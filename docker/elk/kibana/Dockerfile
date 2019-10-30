# https://github.com/elastic/stack-docker
FROM docker.elastic.co/kibana/kibana:7.4.1

RUN rm /usr/share/kibana/config/kibana.yml
ADD kibana.yml /usr/share/kibana/config/

# Add your kibana plugins setup here
# Example: RUN kibana-plugin install <name|url>
