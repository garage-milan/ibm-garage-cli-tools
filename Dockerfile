FROM registry.access.redhat.com/ubi8/ubi:8.1-408

ENV TERRAFORM_VERSION 0.12.24
ENV TERRAFORM_IBMCLOUD_VERSION 1.9.0
ENV SUPPORTED_CALICO 3.12.0
ENV NVM_VERSION 0.35.2
ENV NODE_VERSION 12
ENV SOLSA_VERSION 0.3.5
ENV KUBECTL_VERSION 1.15.5
ENV YQ_VERSION=4.6.3

RUN dnf install -y dnf-plugins-core --disableplugin=subscription-manager && \
    dnf install -y golang --disableplugin=subscription-manager && \
    dnf install -y sudo --disableplugin=subscription-manager && \
    dnf install -y unzip --disableplugin=subscription-manager && \
    dnf install -y openssl --disableplugin=subscription-manager

##################################
# Calico CLI
##################################

RUN curl -O -L https://github.com/projectcalico/calicoctl/releases/download/v${SUPPORTED_CALICO}/calicoctl && \
    mv ./calicoctl /usr/local/bin/calicoctl && \
    chmod +x /usr/local/bin/calicoctl

# Kustomize
RUN opsys=linux_amd64 && \
    curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases |\
      grep browser_download |\
      grep $opsys |\
      cut -d '"' -f 4 |\
      grep /kustomize/v |\
      sort | tail -n 1 |\
      xargs curl -O -L && \
    tar xzf ./kustomize_v*_${opsys}.tar.gz && \
    mv kustomize /usr/local/bin/kustomize && \
    chmod +x /usr/local/bin/kustomize

##################################
# Terraform
##################################

WORKDIR $GOPATH/bin

# Install Terraform
RUN curl -O -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    chmod +x terraform && \
    rm -rf terraform_${TERRAFORM_VERSION}_linux_amd64.zip

COPY src/bin/* /usr/local/bin/

##################################
# User setup
##################################

# Configure sudoers so that sudo can be used without a password
RUN chmod u+w /etc/sudoers && echo "%sudo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME /home/devops

# Create devops user
RUN groupadd --force sudo && \
    groupadd -g 10000 devops && \
    useradd -u 10000 -g 10000 -G sudo,root -d ${HOME} -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops

USER devops
WORKDIR ${HOME}

COPY --chown=devops:devops src/etc/* ${HOME}/etc/

##################################
# IBM Cloud CLI
##################################

# Install the ibmcloud cli
RUN curl -sL https://ibm.biz/idt-installer | bash && \
    ibmcloud config --check-version=false && \
    ibmcloud plugin install cloud-databases -f && \
    ibmcloud plugin install observe-service -f

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash

RUN echo 'echo "Initializing environment..."' > ${HOME}/.bashrc-ni && \
    echo 'export NVM_DIR="${HOME}/.nvm"' >> ${HOME}/.bashrc-ni && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ${HOME}/.bashrc-ni

# Set the BASH_ENV to /home/devops/.bashrc-ni so that it is executed in a
# non-interactive shell
#ENV BASH_ENV ${HOME}/.bashrc-ni

# Pre-install node v11.12.0
RUN echo ${PWD} && . ./.bashrc-ni && nvm install "v${NODE_VERSION}" && nvm use "v${NODE_VERSION}"

RUN mkdir -p ${HOME}/.terraform.d/plugins
WORKDIR ${HOME}/.terraform.d/plugins

# Install IBM Cloud Terraform Provider
RUN curl -O -L https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v${TERRAFORM_IBMCLOUD_VERSION}/linux_amd64.zip &&\
    unzip linux_amd64.zip && \
    chmod +x terraform-provider-ibm_* &&\
    rm -rf linux_amd64.zip

WORKDIR ${HOME}

# Install yo
RUN . ./.bashrc-ni && npm i -g yo
RUN . ./.bashrc-ni && npm i -g @garage-catalyst/ibm-garage-cloud-cli

# Install solsa
RUN . ./.bashrc-ni && npm i -g solsa@${SOLSA_VERSION}

COPY src/image-message ./image-message
RUN cat ./image-message >> ./.bashrc-ni

#RUN sudo dnf install python3 python3-pip -yv
#RUN sudo ln -s /usr/bin/python3 /usr/bin/python
#RUN sudo ln -s /usr/bin/pip3 /usr/bin/pip
#RUN /usr/bin/python3 -m pip install --user ansible && \
#    echo "export PATH=\"${PATH}:${HOME}/.local/bin\"" >> ./.bashrc-ni

RUN curl -L https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz --output oc-client.tar.gz && \
    tar xzf oc-client.tar.gz && \
    sudo cp openshift-origin-client-tools*/oc /usr/local/bin && \
    sudo chmod +x /usr/local/bin/oc && \
    rm -rf openshift-origin-client-tools* && \
    rm oc-client.tar.gz
#    sudo cp openshift-origin-client-tools*/kubectl /usr/local/bin && \
#    sudo chmod +x /usr/local/bin/kubectl && \

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin

RUN sudo mv /usr/local/bin/helm /usr/local/bin/helm2 && \
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash && \
    sudo mv /usr/local/bin/helm /usr/local/bin/helm3 && \
    sudo ln -s /usr/local/bin/helm2 /usr/local/bin/helm

RUN sudo chown -R devops ${HOME} && sudo chgrp -R 0 ${HOME} && sudo chmod -R g=u ${HOME}

RUN curl -LO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod a+x jq-linux64 && \
    sudo mv jq-linux64 /usr/local/bin/jq

RUN sudo dnf clean all

ENTRYPOINT ["/bin/bash", "--init-file", "/home/devops/.bashrc-ni"]
