IBMURL = https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le/
OD := $(CURDIR)
CONDA_VER := 4.8.3
PREFIX := conda/$(CONDA_VER)
CONDA_DIR := $(OD)/$(PREFIX)
NC = 4
PKGSTB = $(shell sed -e 's~$(IBMURL)~$(PREFIX)/pkgs/~' files.txt | tr '\n' ' ')
PKGS = $(patsubst %.tar.bz2,%,$(PKGSTB))

TFILE = trap "rm $@" SIGINT SIGTERM
TDIR = trap "rm -rf $@" SIGINT SIGTERM

###############################################
# Conda and urls
###############################################
CENV = CONDA_PREFIX=$(CONDA_DIR) CONDA_DIR=$(CONDA_DIR) PATH=$(CONDA_DIR)/bin:${PATH} CONDA_EXE=${CONDA_DIR}/bin/conda CONDA_PYTHON_EXE="" IBM_POWERAI_LICENSE_ACCEPT=yes

Miniconda3-4.7.12.1-Linux-ppc64le.sh:
	if [ -e $@ ]; then \
		touch $@; \
	else \
		curl -sL https://repo.anaconda.com/miniconda/$@ > $@.tmp && mv $@.tmp $@; \
	fi
files.txt:
	wget --cut-dirs=8 -e robots=off -nH -r -A bz2 --spider -L $(IBMURL) 2>&1 | grep -o "https.*tar.bz2" > $@.tmp && mv $@.tmp $@
$(PREFIX): | Miniconda3-4.7.12.1-Linux-ppc64le.sh
	bash $| -b -p $@ -s
	$(CENV); \
	conda config --system --set default_threads 4 && \
	conda config --system --prepend channels https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/ && \
	conda config --system --set channel_priority strict && \
	conda config --system --set auto_update_conda False && \
	conda install -yq conda=$(CONDA_VER) conda-build
	chmod -R a+rX $@
###############################################
# Download and unpack packages
###############################################
#$(PREFIX)/conda-meta/pinned: $(PREFIX)
#	echo "cudatoolkit <10.2" >> $@
#	chmod a+rX $@
#$(MAKE) $(PKGSTB) $(PREFIX)/conda-meta/pinned
pkgs_backup.tar: | $(PREFIX) files.txt
	[ -e new_list.txt ] && rm new_list.txt || echo
	[ -e pkgs_backup.tar ] && tar -ntf pkgs_backup.tar > pkgs_list.txt || echo
	$(MAKE) $(PKGSTB)
	[ -e pkgs_list.txt ] && rm pkgs_list.txt || echo
	$(MAKE) $(PKGS)
	cat $(PREFIX)/pkgs/urls.txt files.txt | sort -u > $(PREFIX)/pkgs/urls.txt
	chmod a+rX $(PREFIX)/pkgs/urls.txt
	[ -e $(PREFIX)/pkgs/urls ] && rm $(PREFIX)/pkgs/urls || echo
	if [ -e $@ ]; then \
		if [ -e new_list.txt ]; then \
			tar -uf $@ $(shell cat new_list.txt | tr '\n' ' '); \
		else \
			touch $@; \
		fi \
	else \
		$(TFILE); tar -cf $@ $(PREFIX)/pkgs/*bz2; \
	fi
$(PREFIX)/pkgs/%.tar.bz2: | files.txt $(PREFIX)
	$(TFILE); \
	if [ -e $@ ]; then \
		touch $@; \
	else \
		if [ -e pkgs_list.txt ]; then \
			grep -q "$@" pkgs_list.txt && tar -xf pkgs_backup.tar $@; \
		else \
			URL=$$(grep $(notdir $@) files.txt); \
			curl -sL $$URL > $@; \
			echo "$$URL" >> new_list.txt; \
		fi \
	fi
	chmod a+rX $@
$(PREFIX)/pkgs/%: | $(PREFIX)/pkgs/%.tar.bz2
	mkdir $@ && $(TDIR); tar -xjf $| -C $@
	chmod -R a+rX $@
###############################################
# Create environments
###############################################
#DEPS = $(PREFIX)/conda-meta/pinned pkgs_backup.tar
DEPS = pkgs_backup.tar
DIRS = $(shell echo modulefiles/python{2,3} modulefiles/{tensorflow,pytorch}-py{2,3} modulefiles/conda)
CCREATE = conda create -yn $(notdir $@) --strict-channel-priority python=$$PYV powerai=$$PAIV
REQARGS = $${ENV} $${PYV} $${PKG} $${PKGV} $${KEY} $${CONDA_DIR} $${FAM}
HOROVOD = 'gxx_linux-ppc64le=7.3.0' cffi cudatoolkit-dev ddl
HOROVOD_BUILD = source activate $(notdir $@) && HOROVOD_CUDA_HOME=$(OD)/$@ HOROVOD_GPU_ALLREDUCE=DDL pip install horovod --no-cache-dir
TFM = export FAM=tensorflow KEY="tensorflow ML machine-learning" PKG=tensorflow-py$${PYV}; envsubst '$(REQARGS)' < templates/pkg.tmpl > modulefiles/$${PKG}/$${PKGV}.lua
PTM = export FAM=pytorch KEY="pytroch ML machine-learning" PKG=pytorch-py$${PYV}; envsubst '$(REQARGS)' < templates/pkg.tmpl > modulefiles/$${PKG}/$${PKGV}.lua
EM = KEY="" envsubst '$(REQARGS)' < templates/env.tmpl > modulefiles/python$${PYV}/$${ENV}.lua

modulefiles:
	mkdir $@ && chmod a+rX $@
modulefiles/conda: | modulefiles
	mkdir $@ && chmod a+rX $@
modulefiles/python2: | modulefiles
	mkdir $@ && chmod a+rX $@
modulefiles/python3: | modulefiles
	mkdir $@ && chmod a+rX $@
modulefiles/tensorflow-py2: | modulefiles
	mkdir $@ && chmod a+rX $@
modulefiles/tensorflow-py3: | modulefiles
	mkdir $@ && chmod a+rX $@
modulefiles/pytorch-py2: | modulefiles
	mkdir $@ && chmod a+rX $@
modulefiles/pytorch-py3: | modulefiles
	mkdir $@ && chmod a+rX $@

modulefiles/conda/$(CONDA_VER).lua: | $(DIRS)
	$(CENV) VER=$(CONDA_VER) envsubst '$$CONDA_DIR $$VER' < templates/conda.tmpl > $@

# PowerAI 1.7.0
$(PREFIX)/envs/py3_powerai_1.7.0: | $(DEPS) $(DIRS)
	export PAIV=1.7.0; export $(CENV) ENV=powerai_$$PAIV PYV=3; \
	$(CCREATE) powerai-rapids=$$PAIV $(HOROVOD) && $(HOROVOD_BUILD)
modulefiles/python3/powerai_1.7.0.lua: | $(DEPS) $(DIRS)
	export $(CENV) ENV=powerai_1.7.0 PYV=3; $(EM) && \
	export PKGV=2.1.0; $(TFM) && \
	export PKGV=1.3.1; $(PTM)
# PowerAI 1.6.2
$(PREFIX)/envs/py3_powerai_1.6.2: | $(DEPS) $(DIRS)
	export PAIV=1.6.2; export $(CENV) ENV=powerai_$$PAIV PYV=3; \
	$(CCREATE) powerai-rapids=$$PAIV $(HOROVOD) && $(HOROVOD_BUILD)
modulefiles/python3/powerai_1.6.2.lua: | $(DEPS) $(DIRS)
	export $(CENV) ENV=powerai_1.6.2 PYV=3; $(EM) && \
	export PKGV=1.15.2; $(TFM) && \
	export PKGV=1.2.0; $(PTM)
# PowerAI 1.6.1
$(PREFIX)/envs/py2_powerai_1.6.1: | $(DEPS) $(DIRS)
	export PAIV=1.6.1; export $(CENV) ENV=powerai_$$PAIV PYV=2; \
	$(CCREATE) powerai=1.6.1 $(HOROVOD)
modulefiles/python2/powerai_1.6.1.lua: | $(DEPS) $(DIRS)
	export $(CENV) ENV=powerai_1.6.1 PYV=2; $(EM) && \
	export PKGV=1.14.0; $(TFM) && \
	export PKGV=1.1.0; $(PTM)
$(PREFIX)/envs/py3_powerai_1.6.1: | $(DEPS) $(DIRS)
	export PAIV=1.6.1; export $(CENV) ENV=powerai_$$PAIV PYV=3; \
	$(CCREATE) $(HOROVOD) && $(HOROVOD_BUILD)
modulefiles/python3/powerai_1.6.1.lua: | $(DEPS) $(DIRS)
	export $(CENV) ENV=powerai_1.6.1 PYV=3; $(EM) && \
	export PKGV=1.14.0; $(TFM) && \
	export PKGV=1.1.0; $(PTM)
# PowerAI 1.6.0
$(PREFIX)/envs/py2_powerai_1.6.0: $(DEPS)
	export PAIV=1.6.0; export $(CENV) ENV=powerai_$$PAIV PYV=2; \
	$(CCREATE) powerai=1.6.0 $(HOROVOD)
modulefiles/python2/powerai_1.6.0.lua: | $(DEPS) $(DIRS)
	export $(CENV) ENV=powerai_1.6.0 PYV=2; $(EM) && \
	export PKGV=1.13.1; $(TFM) && \
	export PKGV=1.0.1; $(PTM)
$(PREFIX)/envs/py3_powerai_1.6.0: $(DEPS)
	export PAIV=1.6.0; export $(CENV) ENV=powerai_$$PAIV PYV=3; \
	$(CCREATE) $(HOROVOD) && $(HOROVOD_BUILD)
modulefiles/python3/powerai_1.6.0.lua: | $(DEPS) $(DIRS)
	export $(CENV) ENV=powerai_1.6.0 PYV=3; $(EM) && \
	export PKGV=1.13.1; $(TFM) && \
	export PKGV=1.0.1; $(PTM)

environments:
	$(MAKE) $(PREFIX)/envs/py3_powerai_1.7.0 modulefiles/python3/powerai_1.7.0.lua
	$(MAKE) $(PREFIX)/envs/py3_powerai_1.6.2 modulefiles/python3/powerai_1.6.2.lua
	$(MAKE) $(PREFIX)/envs/py2_powerai_1.6.1 modulefiles/python2/powerai_1.6.1.lua
	$(MAKE) $(PREFIX)/envs/py3_powerai_1.6.1 modulefiles/python3/powerai_1.6.1.lua
	$(MAKE) $(PREFIX)/envs/py2_powerai_1.6.0 modulefiles/python2/powerai_1.6.0.lua
	$(MAKE) $(PREFIX)/envs/py3_powerai_1.6.0 modulefiles/python3/powerai_1.6.0.lua
	$(MAKE) modulefiles/conda/$(CONDA_VER).lua
	chmod -R a+rX modulefiles

###############################################
# Top level commands
###############################################

all:
	$(MAKE) environments

update:
	rm files.txt
	$(MAKE) pkgs_backup.tar
	$(MAKE) environments

clean:
	rm -rf conda files.txt
