# https://github.com/elastic/stack-docker
FROM docker.elastic.co/logstash/logstash:6.7.2

RUN rm /usr/share/logstash/config/logstash.yml
ADD logstash.yml /usr/share/logstash/config/

ADD logstash.conf /usr/share/logstash/pipeline/
ADD patterns/default.conf /usr/share/logstash/patterns/
ADD patterns/nginx.conf /usr/share/logstash/patterns/
ADD patterns/symfony.conf /usr/share/logstash/patterns/

# Add your logstash plugins setup here
# Example: RUN logstash-plugin install logstash-filter-json
