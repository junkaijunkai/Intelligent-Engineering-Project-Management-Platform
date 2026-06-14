## Project Overview

PmHub is a project designed to support project management and workflow automation in an enterprise's context. Its backend is based on the Microservices architecture, implemented through the Spring Cloud Alibaba framework and Maven, and its frontend is based on the Vue framework.

## Core Modules

### Core Service Modules

- `@pmhub-modules/pmhub-system` - System Management, including role management, department management, menu management, user profile and login status management. This module provides user information for other down-stream services, and is used for permission verification.
- `@pmhub-modules/pmhub-project` - Project and Task Management, supporting project and project task CRUD.
- `@pmhub-modules/pmhub-workflow` - Managing project or task approval processes, based on the Flowable engine
- `@pmhub-modules/pmhub-job` - Setting scheduled operations, for example, pushing notifications of overdue tasks to the user.

### Other Moduls


- `@pmhub-base` - General development components, public to all service modules.

## Important Caveats

- Ignore the `@pmhub-boot` directory, which is a **monolith version**. We **ONLY** discuss the **microservices version** here.

- Notice that `@pmhub-modules/pmhub-gen` is for development use, not a user service, providing templated fullstack code generation for CRUD operations regarding a certain table.
