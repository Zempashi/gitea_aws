
VIRTUAL_ENV_DIR := .venv
VAULT_PASSWORD_FILE = .ansible-vault

ANSIBLE_ARGS ?= $(AA)

ifeq (,$(wildcard ./$(VIRTUAL_ENV_DIR)))

endif
ansible-playbook = ansible-playbook

.DEFAULT_GOAL := deploy

deploy: | $(VAULT_PASSWORD_FILE)
	$(ansible-playbook) 00-site.yml $(ANSIBLE_ARGS)

$(VAULT_PASSWORD_FILE):
	@echo "No password file found [./$@]"
	@echo "Creating one with use input:"
	@read -s vaultpassword; echo $${vaultpassword} > $@



define activate_venv
[ -z "$${VIRTUAL_ENV}" ] \
&& echo "Activating venv" \
&& . ./$(VIRTUAL_ENV_DIR)/bin/activate
endef

virtualenv:
	@selinuxenabled; \
	if [ $$? -eq 0 ]; then \
	    VIRTUALENV_ARGS='--system-site-packages'; \
	    PIP_ARGS='--ignore-installed'; \
	fi; \
	if [ "$${VIRTUAL_ENV}" = "" ]; then \
	    PYTHON_EXE=$$(which python2 || which python); \
	    VIRTUALENV_EXE=$$(which virtualenv); \
	$${VIRTUALENV_EXE} $${VIRTUALENV_ARGS} $(VIRTUAL_ENV_DIR) -p $${PYTHON_EXE}; \
	else \
	    touch $(VIRTUAL_ENV_DIR); \
	fi; \
	$(activate_venv); \
	pip install $${PIP_ARGS} --upgrade setuptools; \
	pip install $${PIP_ARGS} -r requirements.txt

# :vim set noexpandtab shiftwidth=8 softtabstop=0
