FROM ubuntu:18.04

RUN apt update && apt install -qqy wget

ENV JULIA_PATH /opt/julia
ENV PATH $JULIA_PATH/bin:$PATH

RUN mkdir -p $JULIA_PATH && \
    wget -nv -O julia.tar.gz "https://julialang-s3.julialang.org/bin/linux/x64/0.7/julia-0.7.0-linux-x86_64.tar.gz" && \
    tar -xzf julia.tar.gz -C $JULIA_PATH --strip-components 1 && \
    rm julia.tar.gz*


ENV JULIA_PROJECT /home/$USER/src/RDFLib
RUN mkdir -p $JULIA_PROJECT
WORKDIR $JULIA_PROJECT
COPY Project.toml Project.toml
RUN julia -e 'using Pkg; Pkg.instantiate(); Pkg.status()'

COPY src src
COPY test test

CMD ["julia", "-e", "using Pkg; Pkg.test()"]
