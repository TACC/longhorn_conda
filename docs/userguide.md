# Software on Longhorn

## Conda Python Environments

We have deployed a pre-configured version of conda, which is available as a module.
For the best experience, we do not recommend that you install your own version of conda.

### Conda Basics

The conda module can be loaded with

```shell
$ module load conda
```

After loading the module, available conda environments can be listed with

```shell
$ conda env list
```

Environments can be loaded with

```shell
$ conda load [environment]
```

You can unload your environment either by deactivating the environment

```shell
$ conda deactivate
```

or unloading the module

```shell
$ module unload conda
```


### Installing new packages

While you can technically install local packages to your `~/.local` directory with pip, these packages will be detected by other, possibly incompatible, environments.
Instead, we recommend that you install packages directly into a cloned or created environment that you have write permissions on.

#### Create, activate, then install

```shell
$ conda create -n new_env python=3 tensorflow
$ conda activate new_env
$ conda install [new package]
$ pip install [new package]
```

> Note: pip works here because the environment was activated.

#### Clone then install

```shell
$ conda create --name myclone --clone py2_powerai_1.6.1
$ conda install -n myclone [new package]
```

> These custom environments are created in your `$SCRATCH` so they may be purged over time. We recommend that you either keep a [specification file](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#building-identical-conda-environments) somewhere safe like `$HOME`, or containerize your environment for longer-term reproducibility.

#### Discovering packages

Longhorn nodes are a PowerPC architecture, so only pure python and code compiled for PowerPC will run on them.
With that said, packages can be directly searched in conda and pip on the command line

```shell
$ conda search tensorflow-gpu
$ pip search quicksect
```

or browsed online at:

*   [IBM WML CE](https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/#/)
*   linux-ppc64le packages on http://anaconda.org
*   [PyPI](https://pypi.org)

Once again, just be sure to look for packages that support `any` or `ppc64` architectures.

## Python-Based Machine Learning

Longhorn uses the [IBM Watson Machine Learning CE](https://developer.ibm.com/linuxonpower/deep-learning-powerai/library/) platform for machine learning frameworks and packages.
Packages are distributed via Anaconda Python through the [WMLCE](https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/#/) package repository.
We recommend using this repository for several reasons:

*   Modules are tested before release
*   We can provide support for these packages
*   Many machine learning frameworks are precompiled for PowerPC architectures and GPU execution

Each version of PowerAI supported by Longhorn is cached on the filesystem and installed in both Python 2 and 3 environments when possible.

```shell
$ module load conda
$ conda env list

# conda environments:
#
base                     /scratch/conda/4.8.3
py2_powerai_1.6.0        /scratch/conda/4.8.3/envs/py2_powerai_1.6.0
py2_powerai_1.6.1        /scratch/conda/4.8.3/envs/py2_powerai_1.6.1
py3_powerai_1.6.0        /scratch/conda/4.8.3/envs/py3_powerai_1.6.0
py3_powerai_1.6.1        /scratch/conda/4.8.3/envs/py3_powerai_1.6.1
py3_powerai_1.6.2        /scratch/conda/4.8.3/envs/py3_powerai_1.6.2
```

To increase the visibility of these environments and packages, we have also exposed them through standard LMOD modules.

```shell
$ module avail

conda/4.8.3                  pytorch-py3/1.0.1
python2/powerai_1.6.0        pytorch-py3/1.1.0
python2/powerai_1.6.1 (D)    pytorch-py3/1.2.0     (D)
python3/powerai_1.6.0        tensorflow-py2/1.13.1
python3/powerai_1.6.1        tensorflow-py2/1.14.0 (D)
python3/powerai_1.6.2 (D)    tensorflow-py3/1.13.1
pytorch-py2/1.0.1            tensorflow-py3/1.14.0
pytorch-py2/1.1.0     (D)    tensorflow-py3/1.15.2 (D)
```

You will notice that loading a package (not environment) module such as `tensorflow-py3/1.15.2` module also loads the `python3/powerai_1.6.2` module and `py3_powerai_1.6.2 environment`.
That is because each tensorflow and pytorch package redirects to and loads the PowerAI distribution they originate from.

This allows you to immediately start running code:

### TensorFlow

```shell
longhorn$ module load python3/powerai_1.6.2
(py3_powerai_1.6.2) longhorn$ python -c 'import tensorflow; print(tensorflow.test.is_gpu_available())'

2020-04-20 17:32:29.440946: I tensorflow/stream_executor/platform/default/dso_loader.cc:44] Successfully opened dynamic library libcudart.so.10.1
...

2020-04-20 17:32:35.278808: I tensorflow/core/common_runtime/gpu/gpu_device.cc:1325] Created TensorFlow device (/device:GPU:3 with 14927 MB memory) -> physical GPU (device: 3, name: Tesla V100-SXM2-16GB, pci bus id: 0035:04:00.0, compute capability: 7.0)
True
```

Additional information:

* https://www.tensorflow.org/overview
* https://keras.io/
* https://portal.tacc.utexas.edu/software/tensorflow - Please ignore system specific information

### PyTorch

```shell
longhorn$ module load python3/powerai_1.6.2
(py3_powerai_1.6.2) longhorn$ python -c 'import torch; print(torch.cuda.is_available())'

True
```

Additional Information:

* https://pytorch.org

### Horovod

We have pre-installed Horovod in each PowerAI environment.
We also recommend using ddl to launch your distributed models as laid out by this guide:

* https://developer.ibm.com/linuxonpower/2018/08/24/distributed-deep-learning-horovod-powerai-ddl/
