# Use the official linuxserver/code-server image as a base
FROM lscr.io/linuxserver/code-server:latest

# Switch to the root user to install system-wide packages
USER root

#--------------------------------------------------------------------------
# 1. Install All System Dependencies at Once
#--------------------------------------------------------------------------
# Install essential tools and OpenJDK 21 from the system repository.
# This is the most reliable method for installing Java.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    sudo \
    gpg \
    unzip \
    openjdk-21-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

#--------------------------------------------------------------------------
# 2. Install Go (Official Binary Release)
# https://go.dev/doc/install
#--------------------------------------------------------------------------
# Set Go version and download the official binary
ARG GO_VERSION=1.22.5
RUN curl -L "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o "/tmp/go.tar.gz" && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

# Add Go to the system-wide PATH for all users
ENV PATH="/usr/local/go/bin:${PATH}"

#--------------------------------------------------------------------------
# 3. Install Node.js and npm (Official NodeSource distribution)
# https://nodejs.org/en/download/package-manager
#--------------------------------------------------------------------------
# Set Node.js version
ARG NODE_MAJOR=20
# Add NodeSource repository and install Node.js
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#--------------------------------------------------------------------------
# 4. Install Gradle (Official Binary Release)
#--------------------------------------------------------------------------
ARG GRADLE_VERSION=8.9
RUN curl -L "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o "/tmp/gradle.zip" && \
    unzip -d /opt /tmp/gradle.zip && \
    mv /opt/gradle-${GRADLE_VERSION} /opt/gradle && \
    rm /tmp/gradle.zip

#--------------------------------------------------------------------------
# 3. Install VS Code Extensions
#--------------------------------------------------------------------------
# Grant the 'abc' user ownership of its home directory before switching to it
RUN chown -R abc:abc /config

# Switch to the non-root user to install extensions
USER abc

# This is the definitive command:
# - Call the executable directly to avoid s6 dependency
# - Force the correct extensions directory so the runtime can find them
RUN for ext in \
    codezombiech.gitignore \
    dbaeumer.vscode-eslint \
    donjayamanne.githistory \
    golang.go \
    gruntfuggly.todo-tree \
    ms-python.python \
    ms-vscode.makefile-tools \
    mtxr.sqltools \
    redhat.java \
    rooveterinaryinc.roo-cline \
    vscjava.vscode-gradle \
    vscjava.vscode-java-pack \
    yzhang.markdown-all-in-one; \
    do /app/code-server/bin/code-server \
        --extensions-dir /config/extensions \
        --install-extension $ext || echo "Failed to install $ext"; \
    done

# Switch back to root to set global environment variables
USER root

#--------------------------------------------------------------------------
# 5. Set Environment Variables
#--------------------------------------------------------------------------
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV GRADLE_HOME=/opt/gradle
ENV PATH="/usr/local/go/bin:${JAVA_HOME}/bin:${GRADLE_HOME}/bin:${PATH}"
