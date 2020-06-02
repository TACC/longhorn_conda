MCURL = https://repo.anaconda.com/miniconda
MCF = Miniconda3-4.7.12.1-Linux-ppc64le.sh
IBMURL = https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/
OD := $(CURDIR)
CONDA_VER := 4.8.3
PREFIX := conda/$(CONDA_VER)
CONDA_DIR := $(OD)/$(PREFIX)
NC = 4

TFILE = trap "rm $@" SIGINT SIGTERM
TDIR = trap "rm -rf $@" SIGINT SIGTERM

###############################################
# Conda and urls
###############################################
CENV = export CONDA_DIR=$(CONDA_DIR) IBM_POWERAI_LICENSE_ACCEPT=yes; source $(PREFIX)/etc/profile.d/conda.sh

$(PREFIX):
	curl -sL $(MCURL)/$(MCF) > $(MCF).tmp && mv $(MCF).tmp $(MCF)
	bash $(MCF) -b -p $@ -s
	$(CENV); \
	conda config --system --set default_threads 4 && \
	conda config --system --prepend channels https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/ && \
	conda config --system --set channel_priority strict && \
	conda config --system --set auto_update_conda False && \
	conda install -yq conda=$(CONDA_VER)
	chmod -R a+rX $@
	$(MAKE) --no-print-directory $(PREFIX)/conda-meta/pinned
	@rm $(MCF)
$(PREFIX)/conda-meta/pinned: | $(PREFIX)
	@echo "cudatoolkit <10.3" >> $@
	@chmod a+rX $@
###############################################
# Download and unpack packages
###############################################
FINDTB = find $(PREFIX)/pkgs -maxdepth 1 -mindepth 1 -type f -name \*tar.bz2
FINDD = find $(PREFIX)/pkgs -maxdepth 1 -mindepth 1 -type d
PKGSTB = $(shell { $(FINDTB); $(FINDTB); sed -e 's~$(IBMURL)~$(PREFIX)/pkgs/~' files.txt; } | sort | uniq -u | tr '\n' ' ')
PKGSD = { $(FINDD); $(FINDD); $(FINDTB) | sed -e 's/.tar.bz2//'; } | sort | uniq -u | tr '\n' ' '
.PHONY: update
###############################################
update: | $(PREFIX) files.txt
	@rm -f new_list.txt; touch new_list.txt
	@[ -e pkgs_backup.tar ] && tar -ntf pkgs_backup.tar > pkgs_list.txt || touch pkgs_list.txt
	@echo Detected $$(cat pkgs_list.txt | wc -l) cached packages
	@echo Adding $$(echo $(PKGSTB) | wc -w) new packages
	@[ -n "$(PKGSTB)" ] && $(MAKE) --no-print-directory $(PKGSTB) || :
	@echo Unpacking $$($(PKGSD) | wc -w) packages
	@VAL=$$($(PKGSD)); [ -n "$$VAL" ] && $(MAKE) --no-print-directory $$VAL || :
	@# Update URL list
	@cat $(PREFIX)/pkgs/urls.txt files.txt | sort -u > $(PREFIX)/pkgs/urls.txt && \
		chmod a+rX $(PREFIX)/pkgs/urls.txt
	@# Delete checksum file
	@[ -e $(PREFIX)/pkgs/urls ] && rm $(PREFIX)/pkgs/urls || :
	@# Update package tarballs
	@trap "rm pkgs_backup.tar" SIGINT SIGTERM; \
	if [ -e pkgs_backup.tar ]; then \
		if [ -s new_list.txt ]; then \
			echo "Updating pkgs_backup.tar with $$(cat new_list.txt | wc -l) new packages"; \
			tar -uf pkgs_backup.tar $$(cat new_list.txt | tr '\n' ' '); \
		else \
			touch pkgs_backup.tar; \
		fi \
	else \
		echo "Creating pkgs_backup.tar"; \
		tar -cf pkgs_backup.tar $(PREFIX)/pkgs/*bz2; \
	fi
	@rm -f files.txt new_list.txt pkgs_list.txt
files.txt:
	@echo "Polling WML for a list of current packages"
	@$(TFILE); wget --cut-dirs=8 -e robots=off -nH -r -A bz2 --spider -L $(IBMURL) 2>&1 | grep -o "https.*tar.bz2" > $@
$(PREFIX)/pkgs/%.tar.bz2: | $(PREFIX) files.txt
	@if [ ! -e $@ ]; then \
		if [ -e pkgs_list.txt ] && grep -q $@ pkgs_list.txt; then \
			echo "Restoring: $@"; \
			grep -q "$@" pkgs_list.txt && tar -xf pkgs_backup.tar $@; \
		else \
			URL=$$(grep $(notdir $@) files.txt); \
			echo "Downloading: $@"; \
			curl -sL $$URL > $@ && echo "$@" >> new_list.txt; \
		fi; \
		chmod a+rX $@; \
	fi
$(PREFIX)/pkgs/%: | $(PREFIX)/pkgs/%.tar.bz2
	@if [ ! -e $@ ]; then \
		echo "Unpacking: $@"; \
		mkdir $@ && $(TDIR); tar -xjf $| -C $@ && \
		chmod -R a+rX $@; \
	fi
###############################################
# Create environments
###############################################
#DEPS = $(PREFIX)/conda-meta/pinned pkgs_backup.tar
DEPS = $(PREFIX)
DIRS = $(shell echo modulefiles/python{2,3} modulefiles/{tensorflow,pytorch}-py{2,3} modulefiles/conda)
CCREATE = conda create -yn $(notdir $@) --strict-channel-priority python=$$PYV powerai=$$PAIV paramiko
REQARGS = $${ENV} $${PYV} $${PKG} $${PKGV} $${KEY} $${CONDA_DIR} $${FAM}
GET_PYV = $(shell echo $@ | grep -oP "(python|py)\K[23]")
GET_PAIV = $(shell echo $@ | grep -oP "powerai_\K[0-9.]+[0-9]")
VARS = PYV=$(GET_PYV) PAIV=$(GET_PAIV)
LIST = conda list -p $(PREFIX)/envs/py$${PYV}_powerai_$${PAIV}
GET_TFV = $$($(LIST) | grep "^tensorflow\s" | sed -e "s/\s\+/ /g" | cut -f 2 -d ' ')
GET_PTV = $$($(LIST) | grep "^pytorch\s" | sed -e "s/\s\+/ /g" | cut -f 2 -d ' ')
HOROVOD_DEPS = conda install -yn $(notdir $@) --strict-channel-priority gxx_linux-ppc64le cffi cudatoolkit-dev nccl spectrum-mpi
HOROVOD_ARGS = HOROVOD_CUDA_HOME=$(OD)/$@ HOROVOD_GPU_BROADCAST=NCCL HOROVOD_GPU_ALLREDUCE=NCCL
HOROVOD_CHECK = conda list -n $(notdir $@) | grep -q horovod
HOROVOD_BUILD = conda activate $(notdir $@) && $(HOROVOD_ARGS) pip install horovod --no-cache-dir
HOROVOD = if ! $(HOROVOD_CHECK); then $(HOROVOD_DEPS) && $(HOROVOD_BUILD); fi
TFM = export FAM=package KEY="tensorflow ML machine-learning" PKG=tensorflow-py$${PYV}; envsubst '$(REQARGS)' < templates/pkg.tmpl > modulefiles/$${PKG}/$${PKGV}.lua
PTM = export FAM=package KEY="pytroch ML machine-learning" PKG=pytorch-py$${PYV}; envsubst '$(REQARGS)' < templates/pkg.tmpl > modulefiles/$${PKG}/$${PKGV}.lua
EM = KEY="" envsubst '$(REQARGS)' < templates/env.tmpl > modulefiles/python$${PYV}/$${ENV}.lua

modulefiles:
	mkdir $@ && chmod a+rX $@
modulefiles/conda: | modulefiles
	mkdir $@ && chmod a+rX $@
$(shell echo modulefiles/{python,tensorflow-py,pytorch-py}{2,3}): | modulefiles
	mkdir $@ && chmod a+rX $@

modulefiles/conda/$(CONDA_VER).lua: | $(DIRS)
	$(CENV) && VER=$(CONDA_VER) envsubst '$$CONDA_DIR $$VER' < templates/conda.tmpl > $@

# PowerAI 1.6.2 1.7.0
$(shell echo $(PREFIX)/envs/py3_powerai_1.{6.2,7.0}): | $(DEPS) $(DIRS)
	export $(VARS); export ENV=powerai_$$PAIV; $(CENV); \
	$(CCREATE) powerai-rapids=$$PAIV && $(HOROVOD) && chmod -R a+rX $@
# PowerAI 1.6.1 1.6.0
$(shell echo $(PREFIX)/envs/py{2,3}_powerai_1.6.{0,1}): | $(DEPS) $(DIRS)
	export $(VARS); export ENV=powerai_$$PAIV; $(CENV); \
	$(CCREATE) && $(HOROVOD) && chmod -R a+rX $@
# All modulefiles
$(shell echo modulefiles/python{2,3}/powerai_1.{6.0,6.1,6.2,7.0}.lua): | $(DEPS) $(DIRS)
	$(CENV); export $(VARS); export ENV=powerai_$$PAIV; $(EM) && \
	export PKGV=$(GET_TFV); $(TFM) && \
	export PKGV=$(GET_PTV); $(PTM)
.PHONY: environments
environments:
	$(MAKE) --no-print-directory $(PREFIX)/envs/py3_powerai_1.7.0
	$(MAKE) --no-print-directory $(PREFIX)/envs/py3_powerai_1.6.2
	$(MAKE) --no-print-directory $(PREFIX)/envs/py2_powerai_1.6.1
	$(MAKE) --no-print-directory $(PREFIX)/envs/py3_powerai_1.6.1
	$(MAKE) --no-print-directory $(PREFIX)/envs/py2_powerai_1.6.0
	$(MAKE) --no-print-directory $(PREFIX)/envs/py3_powerai_1.6.0
modules:
	$(MAKE) --no-print-directory modulefiles/conda/$(CONDA_VER).lua
	$(MAKE) --no-print-directory modulefiles/python3/powerai_1.7.0.lua
	$(MAKE) --no-print-directory modulefiles/python3/powerai_1.6.2.lua
	$(MAKE) --no-print-directory modulefiles/python2/powerai_1.6.1.lua
	$(MAKE) --no-print-directory modulefiles/python3/powerai_1.6.1.lua
	$(MAKE) --no-print-directory modulefiles/python2/powerai_1.6.0.lua
	$(MAKE) --no-print-directory modulefiles/python3/powerai_1.6.0.lua
	chmod -R a+rX modulefiles
	# Make rpm
	[ -e conda-$(CONDA_VER) ] && rm -rf conda-$(CONDA_VER) || :
	mkdir conda-$(CONDA_VER)
	cp -r modulefiles templates/conda.spec conda-$(CONDA_VER)/
	tar -hczf conda-$(CONDA_VER).tar.gz conda-$(CONDA_VER)
	rpmbuild -tb conda-$(CONDA_VER).tar.gz
	rm -rf conda-$(CONDA_VER)*

###############################################
# Top level commands
###############################################

all:
	$(MAKE) environments

clean:
	rm -rf conda files.txt
