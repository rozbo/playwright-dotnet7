FROM mcr.microsoft.com/dotnet/runtime:7.0-jammy as base

# === INSTALL dependencies ===

RUN apt-get update && \
    # Feature-parity with node.js base images.
    apt-get install -y --no-install-recommends git openssh-client curl gpg && \
    # clean apt cache
    rm -rf /var/lib/apt/lists/* && \
    # Create the pwuser
    adduser pwuser
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN mkdir /ms-playwright

FROM mcr.microsoft.com/dotnet/sdk:7.0-jammy as build
RUN mkdir /ms-playwright && \
    mkdir /ms-playwright-agent && \
    cd /ms-playwright-agent && \
    dotnet new console && \
    echo 'Microsoft.Playwright.Program.Main(args);' > ./Program.cs && \
    dotnet add package Microsoft.Playwright && \
    dotnet build && \
    ls -al /ms-playwright-agent



FROM base as final
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=America/Los_Angeles
ARG DOCKER_IMAGE_NAME_TEMPLATE="mcr.microsoft.com/playwright/dotnet:v%version%-focal"

RUN mkdir /ms-playwright-agent 
COPY --from=build /ms-playwright-agent /ms-playwright-agent
RUN cd /ms-playwright-agent&& \
    ./bin/Debug/net7.0/ms-playwright-agent install --with-deps && \
    ./bin/Debug/net7.0/ms-playwright-agent mark-docker-image "${DOCKER_IMAGE_NAME_TEMPLATE}" && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /ms-playwright-agent && \
    chmod -R 777 /ms-playwright
