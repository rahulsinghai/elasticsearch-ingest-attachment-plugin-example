# elasticsearch-ingest-attachment-plugin-example

Example of how to use ElasticSearch ingest-attachment plugin using JavaScript
- [Plug-in Github URL](https://github.com/elastic/elasticsearch/tree/5.x/plugins/ingest-attachment)

### ElasticSearch installation and configuration

1. Install ElasticSearch 6.5.4

   ```bash
   [/] cd /work/elk/elasticsearch
   [/work/elk/elasticsearch] wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.5.4.tar.gz
   [/work/elk/elasticsearch] tar -zxvf ./elasticsearch-6.5.4.tar.gz
   [/work/elk/elasticsearch] cd elasticsearch-6.5.4
   ```

2. Install corresponding version of [ingest-attachment](https://github.com/elastic/elasticsearch/tree/5.6/plugins/ingest-attachment) plug-in ([6.5.4](https://artifacts.elastic.co/downloads/elasticsearch-plugins/ingest-attachment/ingest-attachment-6.5.4.zip) for ES 6.5.4) on every node in the cluster, and each node must be restarted after installation. This requires Java in path.

   ```bash
   [/work/elk/elasticsearch/elasticsearch-6.5.4] wget https://artifacts.elastic.co/downloads/elasticsearch-plugins/ingest-attachment/ingest-attachment-6.5.4.zip
   [/work/elk/elasticsearch/elasticsearch-6.5.4] ./bin/elasticsearch-plugin install file:///work/elk/elasticsearch/elasticsearch-6.5.4/ingest-attachment-6.5.4.zip
   # OR
   C:\work\elk\elasticsearch\elasticsearch-6.5.4>.\bin\elasticsearch-plugin install file:///C:/work/elk/elasticsearch/ingest-attachment-6.5.4.zip
   -> Downloading file:///work/elk/elasticsearch/elasticsearch-6.5.4/ingest-attachment-6.5.4.zip
   [=================================================] 100% 
   Continue with installation? [y/N]y
   -> Installed ingest-attachment
   ```

3. Make sure to have following settings in your elasticsearch.yml (on all nodes to which your application client will connect)

   ```bash
   [/work/elk/elasticsearch/elasticsearch-6.5.4] vim config/elasticsearch.yml
   cluster.name: docManagementCluster

   node.name: ${HOSTNAME}
   node.master: true            # Enable the node.master role (enabled by default).
   node.data: true              # Enable the node.data role (enabled by default).
   node.ingest: true            # Enable the node.ingest role (enabled by default).
   search.remote.connect: false # Disable cross-cluster search (enabled by default).
   node.ml: false               # Disable the node.ml role (enabled by default in X-Pack).
   xpack.ml.enabled: false      # The xpack.ml.enabled setting is enabled by default in X-Pack.

   path.data: ["/work/elk/elasticsearch/docManagementCluster/data"]
   path.repo: ["/work/elk/elasticsearch/docManagementCluster/backups"]
   path.logs: /work/elk/elasticsearch/docManagementCluster/logs

   network.host: 0.0.0.0

   http.port: 9200              # 9200 default
   transport.tcp.port: 9300     # 9300 default

   # discovery.zen.ping.unicast.hosts: ["crcdsr000001300:9301", "crcdsr000001301:9301", "crcdsr000001302:9301"]
   discovery.zen.minimum_master_nodes: 1
   node.max_local_storage_nodes: 1
   gateway.recover_after_nodes: 1
   action.destructive_requires_name: true  # to disable allowing to delete indices via wildcards * or _all

   ## Add CORS Support
   http.cors.enabled : true
   http.cors.allow-origin : "*"
   # http.cors.allow-methods : OPTIONS, HEAD, GET, POST, PUT, DELETE  # commented out, as already default
   http.cors.allow-headers : X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization
   http.max_content_length : 500mb # Defaults to 100mb

   plugin.mandatory: ingest-attachment
   ```

4. Configure logging using log4j2.properties (on all nodes to which your application client will connect)

   ```bash
   logger.action.level = warn

   appender.rolling.filePattern = ${sys:es.logs.base_path}${sys:file.separator}${sys:es.logs.cluster_name}-%d{yyyy-MM-dd}.log.gz

   appender.rolling.strategy.type = DefaultRolloverStrategy
   appender.rolling.strategy.action.type = Delete
   appender.rolling.strategy.action.basepath = ${sys:es.logs.base_path}
   appender.rolling.strategy.action.condition.type = IfLastModified
   appender.rolling.strategy.action.condition.age = 30D
   appender.rolling.strategy.action.PathConditions.type = IfFileName
   appender.rolling.strategy.action.PathConditions.glob = ${sys:es.logs.cluster_name}-*

   rootLogger.level = warn

   logger.index_search_slowlog_rolling.level = warn

   logger.index_indexing_slowlog.level = warn
   ```

5. (Optional) Install X-Pack (security/shield plug-in) as mentioned [here](https://www.elastic.co/guide/en/x-pack/current/installing-xpack.html#xpack-package-installation).

6. Start ElasticSearch

   ```bash
   [/work/elk/elasticsearch/elasticsearch-6.5.4]./bin/elasticsearch
   ```

### ElasticSearch index setup

1. Create a template and index that will map to it. Make sure you have the data field in your map (same name of the "field" in your attachment processor), so ingest will process and populate data field with the document content. Open sense plugin and run:

   ```bash
   DELETE /policies
   DELETE _template/template-policies

   PUT _template/template-policies
   {
     "order": 0,
     "index_patterns": "policies*",
     "settings": {
       "number_of_shards": 1,
       "number_of_replicas": 0,
       "refresh_interval": "1s"
     },
     "mappings": {
       "policy": {
         "properties": {
           "@timestamp": {
             "type": "date",
             "format": "strict_date_optional_time||epoch_millis"
           },
           "id": {
             "type": "keyword", 
             "store":false,
             "index": false
           },
           "message": {
             "type": "keyword", 
             "store":false,
             "index": false
           },
           "filename": {
             "type": "keyword",
             "ignore_above": 256
           },
           "isEnabled": {
             "type": "boolean"
           },
           "data": {
             "type": "text",
             "fields": {
               "keyword": {
                 "type": "keyword",
                 "ignore_above": 256
               }
             }
           },
           "attachment" : {
             "properties" : {
               "content_length" : { "type": "long" },
               "author" : {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 }
               },
               "date" : {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 }
               },
               "language" : {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 }
               },
               "name" : {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 }
               },
               "title" : {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 }
               },
               "keywords" : {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 }
               },
               "content_type": {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 }
               },
               "content": {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 },
                 "analyzer": "english",
                 "term_vector": "with_positions_offsets"
               }
            }
          }
         },
         "dynamic_templates": [
           {
             "strings": {
               "match_mapping_type": "*",
               "mapping": {
                 "type": "text",
                 "fields": {
                   "keyword": {
                     "type": "keyword",
                     "ignore_above": 256
                   }
                 }
               }
             }
           }
         ]
       }
     }
   }
 
   PUT /policies
   GET /policies/_mapping
   ```

2. Create your ingest processor (attachment) pipeline:

   ```bash
   DELETE _ingest/pipeline/attachment
   PUT _ingest/pipeline/attachment
   {
     "description" : "Extract attachment information",
     "processors" : [
       {
         "attachment" : {
           "field" : "data",
           "target_field" : "attachment",
           "indexed_chars" : -1,
           "ignore_missing" : true
         }
       }
     ]
   }
   ```

3. Then you can make a PUT (not POST) to your index using the pipeline you've created:

   ```bash
   PUT policies/policy/0?pipeline=attachment&refresh=true&pretty=1
   {
     "@timestamp": "2017-05-18T15:21:39.465Z",
     "filename": "abc.txt",
     "isEnabled": false,
     "data": "e1xydGYxXGFuc2kNCkxvcmVtIGlwc3VtIGRvbG9yIHNpdCBhbWV0DQpccGFyIH0="
   }
   PUT /policies/policy/1?pipeline=attachment&refresh=true&pretty=1
   {
     "@timestamp": "2017-05-18T15:21:39.465Z",
     "filename": "def.txt",
     "isEnabled": true,
     "data": "IkdvZCBTYXZlIHRoZSBRdWVlbiIgKGFsdGVybmF0aXZlbHkgIkdvZCBTYXZlIHRoZSBLaW5nIg=="
   }
   GET policies/policy/0
   GET policies/policy/1
   ```

4. Via command line ingest more sample documents by running following commands in command shell:

   ```bash
   [/work/github/elasticsearch-ingest-attachment-plugin-example]./bin/indexFile.sh -i 3 -f ./samples/risk-assessment-and-policy-template.doc
   [/work/github/elasticsearch-ingest-attachment-plugin-example]./bin/indexFile.sh -i 5 -f ./samples/sample-risk-mgt-policy-and-procedure.pdf
   [/work/github/elasticsearch-ingest-attachment-plugin-example]./bin/indexFile.sh -i 8 -f ./samples/englishAnalyzer.doc
   [/work/github/elasticsearch-ingest-attachment-plugin-example]./bin/indexFile.sh -i 10 -f ./samples/Credit\ Risk\ Policy\ Formulation.xlsx
   ```

5. Search the documents using sense plug-in:

   ```bash
   GET /policies/policy/0?refresh=true
    
   POST /policies/policy/_search?pretty=true
   {
     "query": {
       "match": {
         "attachment.content_type": "text plain"
       }
     }
   }
    
   POST /policies/policy/_search?pretty=true
   {
     "_source": [
       "filename",
       "attachment.content_type",
       "attachment.content_length",
       "attachment.author",
       "attachment.name",
       "attachment.title",
       "attachment.date",
       "attachment.language",
       "attachment.keywords"
     ],
     "query": {
       "match": {
         "attachment.content": "king queen"
       }
     },
     "highlight": {
       "fields": {
         "attachment.content": {}
       }
     }
   }
    
   POST /policies/policy/_search?size=20&pretty=true
   {
     "_source": [
       "filename",
       "attachment.content_type",
       "attachment.content_length",
       "attachment.author",
       "attachment.name",
       "attachment.title",
       "attachment.date",
       "attachment.language",
       "attachment.keywords"
     ],
     "query": {
       "bool": {
         "filter": {
           "term": {
             "isEnabled": true
           }
         }
       }
     }
   }
    
   POST /policies/policy/_search?pretty=true
   {
     "_source": [
       "filename",
       "attachment.content_type",
       "attachment.content_length",
       "attachment.author",
       "attachment.name",
       "attachment.title",
       "attachment.date",
       "attachment.language",
       "attachment.keywords"
     ],
   "query": {
     "bool": { 
       "must": [
         {"match": { "attachment.content": "Retail Credit Risk"}}
       ],
       "filter": [ { 
         "term":  {"isEnabled": true }
       } ]
     }
   },
   "highlight": {
     "tags_schema": "styled",
       "fields": {
         "attachment.content": {
           "pre_tags": [
             "<mark>"
           ],
           "post_tags": [
             "</mark>"
           ],
           "fragment_size": 150,
           "number_of_fragments": 5,
           "order": "score"
         }
       }
     }
   }
   ```

## Configuration and installation of UI

1. First, install Homebrew:

   ```bash
   $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
   ```

2. Then, brew update to ensure your Homebrew is up to date.

   ```bash
   $ brew update
   ```

3. As a safe measure, run brew doctor to make sure your system is ready to brew. Follow any recommendations from brew doctor.

   ```bash
   $ brew doctor
   ```

4. Install Node.js:

   ```bash
   $ brew install node
   ```

   It will be installed at ```/usr/local/Cellar/node/8.6.0```

5. Install latest npm

   ```bash
   npm i -g npm
   /usr/local/bin/npm -> /usr/local/lib/node_modules/npm/bin/npm-cli.js
   /usr/local/bin/npx -> /usr/local/lib/node_modules/npm/bin/npx-cli.js
   + npm@5.4.2
   added 21 packages, removed 22 packages and updated 19 packages in 20.793s
   ```

6. Configure `~/.npmrc` file used by `npm` if you sit behind proxy server:

   ```bash
   $ vim ~/.npmrc
   strict-ssl=true
   registry=http://your.company.node.repo.server:8081/nexus/content/groups/npm-read/
   proxy=http://http_user:http_password@http_proxy_host:http_proxy_port/
   https-proxy=http://http_user:http_password@http_proxy_host:http_proxy_port/
   cafile=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
   ```

7. If you don't have sudo / root access, then you need to change default npm modules location. Check [this](http://www.competa.com/blog/how-to-run-npm-without-sudo/) for complete steps.

   ```bash
   $ npm config set prefix ~/npm
   ```

   Then edit your .profile/.bashrc/.kshrc/.bash_profile and add:

   ```bash
   export NODE_PATH="$NODE_PATH:$HOME/npm/lib/node_modules"
   export PATH="./:$PATH:$HOME/bin:$JAVA_HOME/bin:$HOME/npm/bin"
   ```

8. Install yarn (bootstrap has a dependency on git; if git is not available, then copy paste ui/node_modules folder from the machine where git is available):

   ```bash
   $ npm install -g yarn
   ~/npm/yarn -> ~/npm/lib/node_modules/yarn/bin/yarn.js
   ~/npm/yarnpkg -> ~/npm/lib/node_modules/yarn/bin/yarn.js
   └── yarn@1.12.3
   updated 1 package in 3.162s
   ```

9. Configure `YARN` (`%USERPROFILE%\.yarnrc` in Windows) file, if you sit behind proxy server:

   ```bash
   $ vim ~/.yarnrc
   registry "https://nexus.your.company/repository/npm-group"
   "--global-folder" "C:\\work\\software\\yarn\\data\\global"
   ca null
   cache-folder "C:\\work\\software\\yarn\\cache"
   init-license Apache-2.0
   lastUpdateCheck 1546011701426
   prefix "C:\\work\\software\\yarn"
   strict-ssl false
   ```
   
   Following commands also resulted in working in a proxied environment:
   
   ```bash
   npm config delete proxy -g
   npm config delete https-proxy -g
   npm config delete https_proxy -g
   npm config set no_proxy "nexus.your.company,localhost"
   npm config set registry https://nexus.your.company/repository/npm-group
   npm config set strict-ssl false
   npm config set ca null
   
   npm install -g yarn
   
      
   yarn config delete proxy
   yarn config delete https-proxy
   yarn config delete https_proxy
   yarn config delete no_proxy
   
   yarn config set prefix C:\work\software\yarn
   yarn config set init-license Apache-2.0
   yarn config set registry https://nexus.your.company/repository/npm-group
   yarn config set strict-ssl false
   yarn config set ca null
   
   yarn config list
   yarn add bootstrap@4.2.1
   yarn add jquery@3.3.1
   yarn add knockout@3.4.2
   yarn add fontawesome@5.6.3
   yarn add elasticsearch@15.2.0
   yarn add popper.js@^1.14.6
   ```

10. Then go to directory where you put `package.json` and download all the dependencies mentioned in `package.json`:

   ```bash
   $ cd /work/github/elasticsearch-ingest-attachment-plugin-example/ui
   [/work/github/elasticsearch-ingest-attachment-plugin-example/ui] yarn
   ```

11. After that you will get all required dependencies for this example to run.
   It should run as local server not as files so you need to host it somehow.
   The simplest way will be:

   ```bash
   [/work/github/elasticsearch-ingest-attachment-plugin-example] npm install -g lite-server
   ~/npm/bin/lite-server -> ~/npm/lib/node_modules/lite-server/bin/lite-server
   ~/npm/lib
   └─┬ lite-server@2.3.0 
   $ npm list -g --depth=0
   ~/npm/lib
   ├── yarn@1.12.3
   └── lite-server@2.3.0
   ```

12. Go to the directory where `index.html` is and start the web server:

   ```bash
   [/work/github/elasticsearch-ingest-attachment-plugin-example/ui] lite-server
   Did not detect a `bs-config.json` or `bs-config.js` override file. Using lite-server defaults...
   ** browser-sync config **
   { injectChanges: false,
     files: [ './**/*.{html,htm,css,js}' ],
     watchOptions: { ignored: 'node_modules' },
     server: { baseDir: './', middleware: [ [Function], [Function] ] } }
   [Browsersync] Access URLs:
    ------------------------------------
       Local: http://localhost:3000
    External: http://10.10.10.10:3000
    ------------------------------------
             UI: http://localhost:3001
    UI External: http://10.10.10.10:3001
    ------------------------------------
   [Browsersync] Serving files from: ./
   [Browsersync] Watching files...
   18.12.28 18:31:13 304 GET /index.html
   18.12.28 18:31:14 304 GET /node_modules/bootstrap/dist/css/bootstrap.css
   18.12.28 18:31:14 304 GET /node_modules/font-awesome/css/font-awesome.css
   18.12.28 18:31:14 304 GET /node_modules/jquery/dist/jquery.js
   18.12.28 18:31:14 304 GET /node_modules/bootstrap/dist/js/bootstrap.js
   18.12.28 18:31:14 304 GET /node_modules/knockout/build/output/knockout-latest.debug.js
   18.12.28 18:31:14 304 GET /node_modules/elasticsearch-browser/elasticsearch.js
   18.12.28 18:31:14 304 GET /node_modules/font-awesome/fonts/fontawesome-webfont.woff2
   ```

## Migrating from Bower to Yarn

**NOTE**: If in Windows, then you will need to install Git with Git commands supported in Command prompt.

After running `yarn install` in above steps, run following:

```bash
$ cd C:\work\github\elasticsearch-ingest-attachment-plugin-example\ui

$ npm i yarn -g
C:\Users\c0252882\AppData\Roaming\npm\yarn -> C:\Users\c0252882\AppData\Roaming\npm\node_modules\yarn\bin\yarn.js
C:\Users\c0252882\AppData\Roaming\npm\yarnpkg -> C:\Users\c0252882\AppData\Roaming\npm\node_modules\yarn\bin\yarn.js
+ yarn@1.12.3
added 1 package in 5.609s

$ yarn -v

$ npm install -g bower
npm WARN deprecated bower@1.8.4: We dont recommend using Bower for new projects. Please consider Yarn and Webpack or Parcel. You can read how to migrate legacy project here: https://bower.io/blog/2017/how-to-migrate-away-from-bower/
C:\Users\c0252882\AppData\Roaming\npm\bower -> C:\Users\c0252882\AppData\Roaming\npm\node_modules\bower\bin\bower
+ bower@1.8.4
added 1 package from 1 contributor in 105.324s

$ bower -v

$ npm i bower-away -g
C:\Users\c0252882\AppData\Roaming\npm\bower-away -> C:\Users\c0252882\AppData\Roaming\npm\node_modules\bower-away\cli.js
+ bower-away@1.1.2
added 156 packages from 80 contributors in 104.232s

$ bower-away
```

## Deploying on production
1. `lite-server` is supposed to be used only for debug/development purpose. It can't run as a daemon process. Hence, we need to install `http-server` and `forever` node modules:
   ```bash
   npm install -g http-server
   npm install -g forever
   ```
2. Edit `index.html` in `ui` folder with correct ElasticSearch cluster details.
3. Edit `startserver.js` in `ui` folder with correct path to `node_modules` folder and `hostname`.
4. Start `http-server`:
   ```bash
   cd /work/github/elasticsearch-ingest-attachment-plugin-example/ui
   forever start startserver.js
   ```
