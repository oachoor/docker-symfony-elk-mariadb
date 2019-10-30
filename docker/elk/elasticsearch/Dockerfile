# https://github.com/elastic/stack-docker
FROM docker.elastic.co/elasticsearch/elasticsearch:7.4.1

RUN rm /usr/share/elasticsearch/config/elasticsearch.yml
ADD elasticsearch.yml /usr/share/elasticsearch/config/

# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu
