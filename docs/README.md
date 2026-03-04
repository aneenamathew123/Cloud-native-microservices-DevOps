## Troubleshooting-DNS errors

## Scenario:
While running a minimal stack provided for the opentelemetry ecommerce application, the frontend produced the following error: 
" UNAVAILABLE: Name resolution failed for target dns:product-catalog:3550 " that is, the frontend unable to reach the product
catalog service.

## Steps taken to troubleshoot
I tried to trace it back to:

- Checked the  product-catalog contianer status "docker compose ps"
- Investigated the root cause of restarting product-catalog service by verfiying the container exit code status. 
- The product-catalog container exited with status 1 means application crashing
- Checked the container logs and verfied mounted directory src/product-catalog/products
- The mounted directory was empty and caused the service to fail to startup.

## Root Cause Analysis:
- The product catalog service requires product information from database and the missing database dependency
cause the empty directory and the service exited during initialization.
Sicne the stopped container cause the Docker DNS resolution problem and the frontend gRPC call to fail.

## Fix:
- Ensure the database dependency to start before product-catalog service and populate the directory with required JSON files.

## Lessons learned:

- Docker DNS only resolves running containers
- Checking dependencies is a good practice in distributed systems.
- Container exit codes help diagnose failures
- Service discovery errors often originate from downstream service crashes

