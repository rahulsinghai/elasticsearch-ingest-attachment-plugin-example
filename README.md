# elasticsearch-ingest-attachment-plugin-example
Example of how to use ElasticSearch ingest-attachment plugin using JavaScript
- [Plug-in Github URL](https://github.com/elastic/elasticsearch-mapper-attachments)

## Configuration and installation
1. First, install Homebrew:
   ```
   $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
   ```
2. Then, brew update to ensure your Homebrew is up to date.
   ```
   $ brew update
   ```
3. As a safe measure, run brew doctor to make sure your system is ready to brew. Follow any recommendations from brew doctor.
   ```
   $ brew doctor
   ```
4. Install Node.js:
   ```
   $ brew install node
   ```
   It will be installed at ```/usr/local/Cellar/node/5.7.1```
5. Install bower:
   ```
   $ npm install -g bower
   /usr/local/bin/bower -> /usr/local/lib/node_modules/bower/bin/bower
   /usr/local/lib
   └── bower@1.7.7
   ```
6. Then go to directory where you put bower.json
   ```
   $ cd /work/fusioncell/spikes/singhai1/es-mapper-attachments-plugin-example
   ```
7. Then download all the dependencies mentioned in bower.json
   ```
   [/work/fusioncell/spikes/singhai1/es-mapper-attachments-plugin-example]$ bower install
   ```
8. After that you will get all required dependencies for this example to run.
   It should run as local server not as files so you need to host it somehow.
   The simplest way will be:
   ```
   [/work/fusioncell/spikes/singhai1/es-mapper-attachments-plugin-example]$ npm install -g lite-server
   ```
   Go to the directory where index.html is and start the web server:
   ```
   [/work/fusioncell/spikes/singhai1/es-mapper-attachments-plugin-example/ui]$ lite-server
   ```

### ElasticSearch configuration
1. Install ElasticSearch 1.6.x
2. Install corresponding version of [elasticsearch-mapper-attachments](https://github.com/elastic/elasticsearch-mapper-attachments) plug-in (2.6.0 for ES 1.6.x).
3. Install shield plug-in and setup a new user credentials.
4. Make sure to have following settings in your elasticsearch.yml
   ```
   ## Add CORS Support
   http.cors.enabled : true
   http.cors.allow-origin : "*"
   http.cors.allow-methods : OPTIONS, HEAD, GET, POST, PUT, DELETE
   http.cors.allow-headers : X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization
   
   cluster.name: fusion2
   node.name: ${HOSTNAME}
   network.host: 0.0.0.0
   discovery.zen.minimum_master_nodes: 1
   node.max_local_storage_nodes: 1
   index.number_of_shards: 1
   index.number_of_replicas: 0
   index.mapping.attachment.indexed_chars: -1
   plugin.mandatory: mapper-attachments
   ```
