FROM python:latest
MAINTAINER namphil "philipn337@gmail.com"
COPY . /app
RUN apt-get update
RUN echo "this is a python web server container"
CMD ["python", "/app/webserver.py"]
EXPOSE 9000
