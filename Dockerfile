FROM nvidia/cuda:11.6.0-runtime-ubuntu20.04

# install required tools
RUN apt-get update && \
	apt-get install -y tzdata && \
	apt-get -y install python3 python3-pip git ssh && \
	pip install flask && \
 	mkdir /root/sample-svc

# prepare the workspace 	
COPY . /root/sample-svc
WORKDIR /root/sample-svc
ADD cuda_install.sh /root/sample-svc/cuda_install.sh
RUN chmod +x /root/sample-svc/cuda_install.sh
RUN /root/sample-svc/cuda_install.sh
RUN chmod +x start_sample_service.sh

EXPOSE 5000

ENTRYPOINT ["./start_sample_service.sh"]
