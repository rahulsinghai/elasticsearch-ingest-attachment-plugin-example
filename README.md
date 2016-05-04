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
   └── bower@1.7.9
   ```
6. Then go to directory where you put bower.json
   ```
   $ cd /work/github/elasticsearch-ingest-attachment-plugin-example
   ```
7. Then download all the dependencies mentioned in bower.json
   ```
   [/work/github/elasticsearch-ingest-attachment-plugin-example]$ bower install
   ```
8. After that you will get all required dependencies for this example to run.
   It should run as local server not as files so you need to host it somehow.
   The simplest way will be:
   ```
   [/work/github/elasticsearch-ingest-attachment-plugin-example]$ npm install -g lite-server
   ```
   Go to the directory where index.html is and start the web server:
   ```
   [/work/github/elasticsearch-ingest-attachment-plugin-example/ui]$ lite-server
   ```

### ElasticSearch configuration
1. Install ElasticSearch 2.3.2
2. Install corresponding version of [elasticsearch-mapper-attachments](https://github.com/elastic/elasticsearch/tree/master/plugins/mapper-attachments) plug-in ([3.1.2](http://mvnrepository.com/artifact/org.elasticsearch/elasticsearch-mapper-attachments/3.1.2) for ES 2.3.2).
3. Install shield plug-in and setup a new user credentials.
4. Make sure to have following settings in your elasticsearch.yml
   ```
   ## Add CORS Support
   http.cors.enabled : true
   http.cors.allow-origin : "*"
   http.cors.allow-methods : OPTIONS, HEAD, GET, POST, PUT, DELETE
   http.cors.allow-headers : X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization
   
   cluster.name: mycluster
   node.name: ${HOSTNAME}
   network.host: 0.0.0.0
   discovery.zen.minimum_master_nodes: 1
   node.max_local_storage_nodes: 1
   index.number_of_shards: 1
   index.number_of_replicas: 0
   index.mapping.attachment.indexed_chars: -1
   plugin.mandatory: mapper-attachments
   ```

### ElasticSearch index setup
1. Open sense plugin and run:
   ```
   DELETE /policies

   PUT /policies
   {
     "settings" : {
       "index" : {
         "number_of_shards" : 1,
         "number_of_replicas" : 0,
         "mapping.attachment.indexed_chars": -1,
         "mapping.attachment.ignore_errors": false,
         "mapping.attachment.detect_language": true
       }
     }
   }

   PUT /policies/risk/_mapping
   {
     "risk" : {
       "properties" : {
         "isEnabled": {"type": "boolean"},
         "policy" : {
           "type" : "attachment",
           "fields" : {
             "author" : { "store" : true },
             "content_length" : { "store" : true },
             "date" : { "store" : true },
             "language" : { "store" : true },
             "name" : { "store" : true },
             "title" : { "store" : true },
             "keywords" : { "store" : true },
             "content_type": { "store": true },
             "content": {
               "type": "string",
               "analyzer": "english",
               "term_vector": "with_positions_offsets",
               "store": true
             }
           }
         }
       }
     }
   }
   ```
2. Check for mapping:
   ```
   GET policies/_mapping
   GET policies/_mapping/risk
   ```
3. Index few documents:
   ```
   PUT /policies/risk/0?refresh=true&pretty=1
   {
       "isEnabled" : true,
       "policy" : {
         "_author" : "DEF PQR",
         "_language" : "en",
         "_name" : "UK King Queen",
         "_title" : "DEFs vision",
         "_indexed_chars" : -1,
         "_content" : "IkdvZCBTYXZlIHRoZSBRdWVlbiIgKGFsdGVybmF0aXZlbHkgIkdvZCBTYXZlIHRoZSBLaW5nIg=="
       }
   }

   PUT /policies/risk/1?refresh=true&pretty=1
   {
       "isEnabled" : true,
       "policy" : {
         "_author" : "ABC XYZ",
         "_language" : "en",
         "_name" : "policy",
         "_title" : "ABCs Policy",
         "_keyword" : "credit, risk, policy",
         "_content_type" : "text/plain; charset=ISO-8859-1",
         "_content" : "e1xydGYxXGFuc2kNCkxvcmVtIGlwc3VtIGRvbG9yIHNpdCBhbWV0DQpccGFyIH0="
       }
   }
   ```
4. Index more sample documents by running following commands in command shell:
   ```
   [/work/github/elasticsearch-ingest-attachment-plugin-example]$./bin/indexFile.sh -i 3 -f ./samples/risk-assessment-and-policy-template.doc
   [/work/github/elasticsearch-ingest-attachment-plugin-example]$./bin/indexFile.sh -i 5 -f ./samples/sample-risk-mgt-policy-and-procedure.pdf
   [/work/github/elasticsearch-ingest-attachment-plugin-example]$./bin/indexFile.sh -i 8 -f ./samples/englishAnalyzer.doc
   [/work/github/elasticsearch-ingest-attachment-plugin-example]$./bin/indexFile.sh -i 10 -f ./samples/Credit\ Risk\ Policy\ Formulation.xlsx
   ```
5. Search the documents using sense plug-in:
   ```
   GET /policies/risk/0?refresh=true&pretty=1

   POST /policies/risk/_search?pretty=true
   {
     "fields": [ "policy.content_type" ],
     "query": {
       "match": {
         "policy.content_type": "text plain"
       }
     }
   }

   POST /policies/risk/_search?pretty=true
   {
     "fields": [],
     "query": {
       "match": {
         "policy.content": "king queen"
       }
     },
     "highlight": {
       "fields": {
         "policy.content": {
         }
       }
     }
   }

   POST /policies/risk/_search?pretty=true
   {
     "fields": ["policy.content_type", "policy.author", "policy.name", "policy.title", "policy.content_length", "policy.date", "policy.language", "policy.keywords"]
   }

   POST /policies/risk/_search?pretty=true
   {
       "fields": ["policy.content_type", "policy.author", "policy.name", "policy.title", "policy.content_length", "policy.date", "policy.language", "policy.keywords"],
       "query": {
           "match": {
               "policy.content": "Retail Credit Risk"
           }
       },
       "highlight": {
           "tag_schema" : "styled",
           "fields": {
               "policy.content": {
                   "pre_tags" : ["<mark>"],
                   "post_tags" : ["</mark>"],
                   "fragment_size" : 50,
                   "number_of_fragments" : 10,
                   "order" : "score"
               }
           }
       }
   }
   ```
