# Discover Installed Software


## Conda Python Environments

TACC staff has deployed a pre-configured version of [conda](https://docs.conda.io), available as a [module](https://portal.tacc.utexas.edu/software/modules).
For the best experience on TACC resources, we recommend that you do not install your own version of Conda.

### Conda Basics

The conda module can be loaded with

```
$ module load conda
```

After loading the module, available conda environments can be listed with

```
$ conda env list
```

Environments can be loaded with

```
$ conda load [environment]
```

In this case, `[environment]` is a place-holder for the name of a specific environment.
When finished using an environment, it can be exited by either deactivating the environment

```
$ source deactivate
```

or unloading the module

```
$ module unload conda
```

### Installing new packages

While you can technically install local packages to your `~/.local` directory with `pip`, they will be detected by other environments, which may cause issues since they supersede all others.
Instead, we recommend that you install packages directly into a cloned or created environment where you have write permissions.

#### Create, activate, then install

```
$ conda create -n new_env python=3 tensorflow
$ conda activate new_env
$ conda install [new package]
$ pip install [new package]
```

> Note: `pip` works here because the environment was activated.

#### Clone and Install

```
$ conda create --name myclone --clone py2_powerai_1.6.1
$ conda install -n myclone [new package]
```


#### Discovering Packages

Longhorn nodes are a PowerPC architecture, so only pure python and code compiled for PowerPC will run on them.
With that said, packages can be directly searched in `conda` and `pip` on the command line:

```
$ conda search tensorflow-gpu
$ pip search quicksect
```

or browsed online at

*   [IBM WML CE](https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/#/)
*   linux-ppc64le packages on conda [http://anaconda.org](http://anaconda.org)
*   [PyPI](https://pypi.org)

Once again, look for packages that support either `any` or `ppc64` architectures.

## Python-Based Machine Learning

Longhorn uses the [IBM Watson Machine Learning CE](https://developer.ibm.com/linuxonpower/deep-learning-powerai/library/) platform for machine learning frameworks and packages.
Packages are distributed via Anaconda Python through the [WMLCE](https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/#/) repository.
While you may be used to using `pip` to install the latest versions of your preferred machine learning frameworks, we recommend using this repository for several reasons:

*   The modules and environments are tested by IBM before release
*   Each PowerAI release contains a curated ecosystem of machine learning packages precompiled for PowerPC and GPU execution
*   The environments are functional and known, so we can provide support for these packages

Each version of PowerAI supported by Longhorn is cached on the file system and installed in both Python 2 and 3 environments when possible.

```
$ module load conda
$ conda env list
# conda environments:
#
base                  *  /scratch/apps/conda/4.8.3
py2_powerai_1.6.0        /scratch/apps/conda/4.8.3/envs/py2_powerai_1.6.0
py2_powerai_1.6.1        /scratch/apps/conda/4.8.3/envs/py2_powerai_1.6.1
py3_powerai_1.6.0        /scratch/apps/conda/4.8.3/envs/py3_powerai_1.6.0
py3_powerai_1.6.1        /scratch/apps/conda/4.8.3/envs/py3_powerai_1.6.1
py3_powerai_1.6.2        /scratch/apps/conda/4.8.3/envs/py3_powerai_1.6.2
py3_powerai_1.7.0        /scratch/apps/conda/4.8.3/envs/py3_powerai_1.7.0
```

These environments contain the following machine learning packages:

*   [Caffe](https://caffe.berkeleyvision.org/)
*   [RAPIDS](https://rapids.ai/)
*   [Snap ML](https://ibmsoe.github.io/snap-ml-doc/v1.6.0/)
*   [PyTorch](https://pytorch.org/)
*   [TensorFlow](https://www.tensorflow.org/overview)
*   [XGBoost](https://xgboost.readthedocs.io/en/latest/python/)

To increase the visibility of these environments and packages, we have also exposed some through standard LMOD modules.

```
$ ml avail

---------------- /opt/apps/modulefiles --------------------
   conda/4.8.3           (L,D)    pytorch-py3/1.1.0
   python2/powerai_1.6.0          pytorch-py3/1.2.0
   python2/powerai_1.6.1 (D)      pytorch-py3/1.3.1     (D)
   python3/powerai_1.6.0          tensorflow-py2/1.13.1
   python3/powerai_1.6.1          tensorflow-py2/1.14.0 (D)
   python3/powerai_1.6.2          tensorflow-py3/1.13.1
   python3/powerai_1.7.0 (D)      tensorflow-py3/1.14.0
   pytorch-py2/1.0.1              tensorflow-py3/1.15.2
   pytorch-py2/1.1.0     (D)      tensorflow-py3/2.1.0  (D)
   pytorch-py3/1.0.1
```

Notice that loading the `tensorflow-py3/1.15.2` module also loads the `python3/powerai_1.6.2` module, which loads the `py3_powerai_1.6.2` conda environment.
That is because each tensorflow and pytorch package redirects to and loads the PowerAI distribution from where they originated.

While you can create conda environments on the login nodes without affecting other users, you must  move to a compute node when running code via an [idev](https://portal.tacc.utexas.edu/software/idev) session.

```
# Allocate a compute node in the development queue for 30 minutes
$ idev -m 30 -p development
```

### TensorFlow

```
$ module load tensorflow-py3/1.15.2
(py3_powerai_1.6.2)$ python -c 'import tensorflow; print(tensorflow.test.is_gpu_available())'
2020-04-20 17:32:29.440946: I tensorflow/stream_executor/platform/default/dso_loader.cc:44] Successfully opened dynamic library libcudart.so.10.1
...
2020-04-20 17:32:35.278808: I tensorflow/core/common_runtime/gpu/gpu_device.cc:1325] Created TensorFlow device (/device:GPU:3 with 14927 MB memory) -> physical GPU (device: 3, name: Tesla V100-SXM2-16GB, pci bus id: 0035:04:00.0, compute capability: 7.0)
True
```

Note that the `(py3_powerai_1.6.2)` decorator is prefixed to your shell’s `$PS1` prompt indicating which conda environment was loaded.

Additional information:

*   [TensorFlow](https://www.tensorflow.org/overview)
*   [Keras](https://keras.io/)
*   [TensorFlow at TACC](https://portal.tacc.utexas.edu/software/tensorflow)
*   [TACC Machine Learning Institute](https://www.tacc.utexas.edu/education/institutes/machine-learning)

### PyTorch

```
$ module load pytorch-py3/1.2.0
(py3_powerai_1.6.2)$ python -c 'import torch; print(torch.cuda.is_available())'
True
```

See [PyTorch](https://pytorch.org/) for additional Information:

### Horovod

Each PowerAI environment contains [Horovod](https://github.com/horovod/horovod) for distributed deep learning.
Horovod requires [minimal changes](https://github.com/horovod/horovod#supported-frameworks) to your code to split your data batches across multiple GPUs and nodes.
Below is an example of running the TensorFlow benchmark suite on two Longhorn nodes with 8 GPUs in total using `ibrun`.

```
# Allocate compute nodes
login1$ idev -N 2 -n 8 -p v100
# Load TensorFlow 2.1.0
c002-001$ module load tensorflow-py3/2.1.0
# Download and checkout benchmarks compatible with TF 2.1
c002-001$ git clone --branch cnn_tf_v2.1_compatible https://github.com/tensorflow/benchmarks.git
c002-001$ cd benchmarks
# Launch with ibrun
c002-001$ ibrun -n 8 python scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --num_gpus=1 --model resnet50 --batch_size 32 --num_batches 100 --variable_update=horovod
TACC:  Starting up job 22832
TACC:  Setting up parallel environment for OpenMPI mpirun.
TACC:  Starting parallel tasks...
…
----------------------------------------------------------------
total images/sec: 2560.04
----------------------------------------------------------------
TACC:  Shutdown complete. Exiting.
```

> Official PowerAI documentation references IBM DDL and `ddlrun`, but we found no significant performance difference between it and NCCL with `ibrun`.
