# graylog
Base config used for a multi site GrayLog setup. A total of four GrayLog servers was used (two servers sitting in two data centres) in the cluster.
A load balancer was placed in front of the GrayLog servers at each site, each site sends logs to the VIP on the load balancer.
An ElasticSearch and MongoDB cluster was setup in AWS, all GrayLog servers connect to these via redundant Direct Connects in each site.
This allowed logs from either site to be searched from any of the GrayLog instances.
