This document explores docker networking concepts using the opentelemetry ecommerce application.
The goal is to understand:
- how network namespaces isolate containers and from the host,
- how Docker Embedded DNS works,  
- how containers communicate within a network. 

## Inspecting Docker network:

This ecommerce application is provided with a default bridge network(Docker0). However, when using Docker compose
a user-defined network is automatically created and all microservices are attached to this user-defined network. 
It is listed using 'docker network ls'. The user-defined network 'opentelemetry-demo' is inspected 
using 'docker network inspect opentelemetry-demo' and understood  that all the services receive an IP address within
the subnet 172.18.0.0/16.

## Docker container networking:

Each services of the application run its own container with an isolated network namespace. This is verified by entering 
the network namespace.
The command 'nsenter -t PID -n' showed container network interface(eth0), loopback interface(lo) and IP address. 


## Docker Embedded DNS:
 
Docker provides an embedded DNS server for automatic service discovery in user-defined networks as compared
to default bridge network. Each service has the NameServer '127.0.0.11' stored on file '/etc/resolv.conf' and it is
verified using  'cat /etc/resolv.conf', This allows containers to communicate each other using service names
instead of IP adresses.


## Key takeaways:

- Docker containers run in isolated network namespaces.
- Each containers has its own IP address and MAC address.
- Docker compose creates a user-defined network for services.
- The Docker bridge acts like a virtual layer2 switch .
- Containers communicate each other using service names through  Docker DNS.
- The Adress Resolution Protocol(ARP) resolves the container IP address to MAC address.


## Output of docker network inspect showing container IP allocation in 172.18.0.0/16 subnet.

![Docker Network Inspect](images/Screenshot-networking.png)


## Docker Networking Architecture for Opentelemetry application:

Each services run its own network namespaces and connected to the user defined opentelemetry-demo network through
a Veth pair.

![Docker Networking Architecture](./images/Networking.jpg) 
