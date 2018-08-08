#!/usr/bin/env python3

import boto3
import botocore
import os
import requests
import time

from cryptography.hazmat.backends import default_backend
from cryptography import x509
from urllib.parse import urljoin


class LetsencryptELB:

    INTERNAL_DATA_URL = 'http://instance-data.ec2.internal/latest/'
    IAM_ROLE_ENDPOINT = 'meta-data/iam/security-credentials/'
    INSTANCE_ENDPOINT = 'dynamic/instance-identity/document/'
    LETSENCRYPT_DIR = '/etc/letsencrypt/live'

    def __init__(self, domain, elb_name, elb_port=None):
        self._session = None
        self.domain = domain
        self.elb_name = elb_name
        self.elb_port = int(elb_port or 443)

    def deploy(self):
        with open(os.path.join(self.LETSENCRYPT_DIR, self.domain, 'privkey.pem')) as filename:
            pem_private_key = filename.read()
        with open(os.path.join(self.LETSENCRYPT_DIR, self.domain, 'cert.pem')) as filename:
            pem_certificate = filename.read()
        with open(os.path.join(self.LETSENCRYPT_DIR, self.domain, 'chain.pem')) as filename:
            pem_certificate_chain = filename.read()
        self.update_certificate(
            self.domain,
            pem_private_key,
            pem_certificate,
            pem_certificate_chain
        )

    @property
    def session(self):
        if self._session is None:
            instance_url = urljoin(self.INTERNAL_DATA_URL,
                                   self.INSTANCE_ENDPOINT)
            instance_doc = requests.get(instance_url)
            instance_doc.raise_for_status()
            get_role_url = urljoin(self.INTERNAL_DATA_URL,
                                   self.IAM_ROLE_ENDPOINT)
            iam_role = requests.get(get_role_url)
            iam_role.raise_for_status()
            credential_url = urljoin(
                urljoin(self.INTERNAL_DATA_URL, self.IAM_ROLE_ENDPOINT),
                iam_role.text
            )
            aws_credentials = requests.get(credential_url)
            aws_credentials.raise_for_status()
            aws_credentials = aws_credentials.json()
            self._session = boto3.Session(
                aws_access_key_id=aws_credentials['AccessKeyId'],
                aws_secret_access_key=aws_credentials['SecretAccessKey'],
                aws_session_token=aws_credentials['Token'],
                region_name=instance_doc.json()['region'])
        return self._session

    @property
    def iam_client(self):
        return self.session.client('iam')

    @property
    def elb_client(self):
        return self.session.client('elb')

    def generate_certificate_name(self, host, certificate):
        if isinstance(certificate, str):
            cert = x509.load_pem_x509_certificate(
                certificate.encode(), default_backend()
            )
        else:
            cert = certificate
        issuer_name = cert.issuer.get_attributes_for_oid(
            x509.NameOID.COMMON_NAME
        )[0].value
        name = host
        if 'fake' in issuer_name.lower():
            name += '+staging'
        return "{name}-{start}-{expiration}-{serial}".format(
            name=name,
            start=cert.not_valid_before.date(),
            expiration=cert.not_valid_after.date(),
            serial=cert.serial,
        )[:128]

    def update_certificate(self, host, pem_private_key, pem_certificate,
                           pem_certificate_chain):
        response = self.iam_client.upload_server_certificate(
            ServerCertificateName=self.generate_certificate_name(host, pem_certificate),
            PrivateKey=pem_private_key,
            CertificateBody=pem_certificate,
            CertificateChain=pem_certificate_chain,
        )
        new_cert_arn = response["ServerCertificateMetadata"]["Arn"]

        count = 0
        while count < 5:
            try:
                self.elb_client.set_load_balancer_listener_ssl_certificate(
                    LoadBalancerName=self.elb_name,
                    SSLCertificateId=new_cert_arn,
                    LoadBalancerPort=self.elb_port,
                )
            except botocore.exceptions.ClientError:
                time.sleep(2**count - 1)
                count += 1
            else:
                break
        if count >= 5:
            raise ValueError("Impossible to update the certificate")


if __name__ == "__main__":
    domain = os.environ['RENEWED_DOMAINS']
    elb_name = os.environ['ELB_NAME']
    elb_port = os.environ.get('ELB_PORT')
    LE = LetsencryptELB(
        domain=domain,
        elb_name=elb_name,
        elb_port=elb_port
    )
    LE.deploy()
