FROM nvidia/cuda:11.6.0-runtime-ubuntu20.04

# install required tools
RUN apt-get update && \
	apt-get install -y tzdata && \
	apt-get -y install python3 python3-pip git ssh

RUN mkdir /root/sample-svc
COPY . /root/sample-svc
WORKDIR /root/sample-svc
ADD cuda_install.sh /root/sample-svc/cuda_install.sh
RUN chmod +x /root/sample-svc/cuda_install.sh
RUN /root/sample-svc/cuda_install.sh
RUN chmod +x start_mse.sh

EXPOSE 5000

ENTRYPOINT ["./start_sample_service.sh"]
