FROM python:3.6-slim

WORKDIR /servo

# Install dependencies
RUN pip3 install requests PyYAML wavefront-api-client
RUN apt update && apt install -y openssh-client


# Install servo
ADD https://raw.githubusercontent.com/opsani/servo-tomcat/master/adjust \
    https://raw.githubusercontent.com/opsani/servo-wavefront/master/measure \
    https://raw.githubusercontent.com/opsani/servo/master/measure.py \
    https://raw.githubusercontent.com/opsani/servo/master/adjust.py \
    https://raw.githubusercontent.com/opsani/servo/master/servo \
    /servo/

RUN chmod a+rwx /servo/adjust /servo/measure /servo/servo

ENV PYTHONUNBUFFERED=1

ENTRYPOINT [ "python3", "servo" ]
