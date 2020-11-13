# Author: David Blyth
# Description: Docker build intended to replicate the FPaDSim environment
#     created by Sergei Chekanov

FROM dbcooper/arch:2017-02-18

# Set up basic environment
RUN pacman -S --noconfirm \
	sed \
	sudo

RUN useradd -m -G wheel fpadsimuser && \
    sed -i.bak 's/# \(%wheel ALL=(ALL) NOPASSWD: ALL\)/\1/' /etc/sudoers

USER fpadsimuser
WORKDIR /home/fpadsimuser

CMD /bin/bash -l

# ROOT
RUN sudo pacman -S --noconfirm \
        awk \
        binutils \
        cmake \
        fakeroot \
        fftw \
        gcc \
        git \
        glew \
        glu \
        grep \
        gsl \
        gzip \
        make \
        python2 \
        libx11 \
        libxft \
        libxpm

ENV ROOT_VERSION 6-10-00

RUN git clone https://github.com/root-project/root.git && \
    cd root && \
    git checkout tags/v$ROOT_VERSION && \
    cd .. && \
    mkdir build && \
    cd build && \
    cmake ../root \
        -Dbuiltin_glew=OFF \
        -Dcxx14=ON \
        -Dgdml=ON \
        -Dgsl_shared=ON \
        -Dmathmore=ON \
        -Dminuit2=ON \
        -Dopengl=ON && \
    make -j30 && \
    sudo make install && \ 
    cd .. && \
    rm -rf build root

RUN sudo bash -c 'echo ". /usr/local/bin/thisroot.sh" > /etc/profile.d/ROOT.sh' && \
    sudo chmod +x /etc/profile.d/ROOT.sh

# CLHEP
RUN sudo pacman -S --noconfirm \
        wget \
        xerces-c

ENV CLHEP_VERSION 2.3.4.4

RUN wget http://proj-clhep.web.cern.ch/proj-clhep/DISTRIBUTION/tarFiles/clhep-$CLHEP_VERSION.tgz -q -O clhep.tgz && \
    tar -xzf clhep.tgz && \
    mv $CLHEP_VERSION/CLHEP ./ && \
    rm -rf $CLHEP_VERSION && \
    mkdir build && \
    cd build && \
    CXXFLAGS=-std=c++14 cmake ../CLHEP && \
    make -j30 && \
    sudo make install && \
    cd .. && \
    rm -rf build CLHEP clhep.tgz

# GEANT4
ENV GEANT4_VERSION 10.3.1

RUN git clone https://github.com/Geant4/geant4.git && \
    cd geant4 && \
    git checkout tags/v$GEANT4_VERSION && \
    cd .. && \
    mkdir build && \
    cd build && \
    cmake ../geant4 \
        -DGEANT4_BUILD_CXXSTD=14 \
        -DGEANT4_INSTALL_DATA=ON \
        -DGEANT4_USE_GDML=ON \
        -DGEANT4_USE_SYSTEM_CLHEP=ON && \
    make -j30 && \
    sudo make install && \
    cd .. && \
    rm -rf build geant4

RUN sudo bash -c 'echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib64" >> /etc/profile.d/geant4.sh' && \
    sudo bash -c 'echo ". /usr/local/bin/geant4.sh" > /etc/profile.d/geant4.sh' && \
    sudo chmod +x /etc/profile.d/geant4.sh

# Oracle JDK
RUN sudo pacman -S --noconfirm \
        file

RUN git clone https://aur.archlinux.org/jdk.git && \
	cd jdk && \
	git checkout eaa4d0bec2f6b573c15c1214c030198215bcb1b2 && \
	makepkg -si --noconfirm && \
	cd .. && \
	rm -rf jdk

# LCIO
ENV LCIO_VERSION 02-09
ENV LCIO_DIR /opt/LCIO

RUN git clone https://github.com/iLCSoft/LCIO.git /opt/LCIO && \
    cd $LCIO_DIR && \
    git checkout tags/v$LCIO_VERSION && \
    cd ~/ && \
    mkdir build && \
    cd build && \
    CXXFLAGS=-std=c++14 cmake $LCIO_DIR \
        -DBUILD_ROOTDICT=ON && \
    make -j30 install && \
    cd ../ && \
    rm -rf build

RUN sudo bash -c "echo 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$LCIO_DIR/lib' >> /etc/profile.d/LCIO.sh" && \
    sudo bash -c "echo 'export PATH=\$PATH:$LCIO_DIR/bin' >> /etc/profile.d/LCIO.sh" && \
    sudo chmod +x /etc/profile.d/LCIO.sh

# iLCUtil
ENV ILCUTIL_DIR /opt/iLCUtil

RUN git clone https://github.com/iLCSoft/iLCUtil.git && \
	cd iLCUtil && \
	git checkout 5332ae883348acbf0f32b4439798937fa2428b06 && \
	cd ../ && \
	mkdir build && \
	cd build && \
	cmake ../iLCUtil -DCMAKE_INSTALL_PREFIX=$ILCUTIL_DIR && \
	make -j30 && \
	sudo make install && \
	cd ../ && \
	rm -rf iLCUtil build && \
	sudo bash -c "echo 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$ILCUTIL_DIR/lib' >> /etc/profile.d/iLCUtil.sh" && \
	sudo chmod +x /etc/profile.d/iLCUtil.sh

# SLIC
ENV SLIC_DIR /opt/slic

RUN git clone https://github.com/decibelCooper/slic.git && \
	cd slic && \
	git checkout 30c6a84ec5d570390ef75fa811117d24afa67462 && \
	echo 'SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -ldl" )' >> CMakeLists.txt && \
	cd ../ && \
	mkdir build && \
	cd build && \
	CXXFLAGS=-std=c++14 cmake ../slic \
		-DINSTALL_DEPENDENCIES=ON \
		-DCMAKE_INSTALL_PREFIX=$SLIC_DIR -DLCIO_DIR=$LCIO_DIR && \
	make -j30 && \
	CXXFLAGS=-std=c++14 cmake ../slic \
		-DINSTALL_DEPENDENCIES=ON \
		-DCMAKE_INSTALL_PREFIX=$SLIC_DIR -DLCIO_DIR=$LCIO_DIR && \
	make -j30 && \
	make install && \
	cd ../ && \
	rm -rf slic build && \
	echo "#!/bin/bash" | sudo bash -c "cat >> /etc/profile.d/SLIC.sh" && \
	echo 'export PATH=$PATH:$SLIC_DIR/bin' | sudo bash -c "cat >> /etc/profile.d/SLIC.sh" && \
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SLIC_DIR/lib' | sudo bash -c "cat >> /etc/profile.d/SLIC.sh" && \
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SLIC_DIR/extdeps/gdml/lib' | sudo bash -c "cat >> /etc/profile.d/SLIC.sh" && \
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SLIC_DIR/extdeps/heppdt/lib' | sudo bash -c "cat >> /etc/profile.d/SLIC.sh" && \
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SLIC_DIR/extdeps/lcdd/lib' | sudo bash -c "cat >> /etc/profile.d/SLIC.sh" && \
	sudo chmod +x /etc/profile.d/SLIC.sh

# LCSIM
RUN sudo pacman -S --noconfirm \
        maven \
        which

ENV LCSIM_COMMIT 917843d955e4de308bb514e6793388e341cfc589

RUN git clone https://github.com/decibelCooper/lcsim.git /opt/lcsim && \
	cd /opt/lcsim && \
	git checkout $LCSIM_COMMIT && \
    mvn -DskipTests && \
	rm -rf ~/.m2

ENV LCSIM_VERSION 4.0-SNAPSHOT

RUN echo "export CLICSOFT=/opt/lcsim; export GEOMCONVERTERDIR=\$CLICSOFT/detector-framework; export GCONVERTER=\$GEOMCONVERTERDIR/target/lcsim-detector-framework-$LCSIM_VERSION-bin.jar" | sudo bash -c "cat >> /etc/profile.d/lcsim.sh" && \
    sudo chmod +x /etc/profile.d/lcsim.sh

# PandoraPFA
ENV PANDORA_PFA_VERSION v02-09-00
ENV PANDORA_DIR /opt/PandoraPFA

RUN git clone https://github.com/PandoraPFA/PandoraPFA.git $PANDORA_DIR && \
	cd $PANDORA_DIR && \
	git checkout $PANDORA_PFA_VERSION && \
	mkdir build && \
	cd build && \
	CXXFLAGS=-std=c++14 cmake -DCMAKE_MODULE_PATH=$ROOTSYS/etc/cmake -DPANDORA_MONITORING=ON -DPANDORA_EXAMPLE_CONTENT=OFF \
		-DPANDORA_LAR_CONTENT=OFF -DPANDORA_LC_CONTENT=ON ../ && \
	make -j30 install && \
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'$PANDORA_DIR'/lib' | sudo bash -c "cat >> /etc/profile.d/PandoraPFA.sh" && \
	sudo chmod +x /etc/profile.d/PandoraPFA.sh

# slicPandora
ENV SLIC_PANDORA_DIR /opt/slicPandora

RUN wget http://www.hep.phy.cam.ac.uk/~marshall/slicPandora_Pandora_v02.09.00_patch1.tar.gz -q -O slicPandora.tar.gz && \
	tar -xzf slicPandora.tar.gz && \
	mv slicPandora/HEAD $SLIC_PANDORA_DIR && \
	mkdir build && \
	cd build && \
	cmake $SLIC_PANDORA_DIR -DILCUTIL_DIR=$ILCUTIL_DIR -DLCIO_DIR=$LCIO_DIR -DPandoraPFA_DIR=$PANDORA_DIR \
		-DPandoraSDK_DIR=$PANDORA_DIR -DLCContent_DIR=$PANDORA_DIR -DCMAKE_SKIP_RPATH=1 && \
	make -j30 install && \
	cd ../ && \
	rm -rf build slicPandora slicPandora.tar.gz && \
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'$SLIC_PANDORA_DIR'/lib' | sudo bash -c "cat >> /etc/profile.d/slicPandora.sh" && \
	echo 'export slicPandora_DIR='$SLIC_PANDORA_DIR | sudo bash -c "cat >> /etc/profile.d/slicPandora.sh" && \
	sudo chmod +x /etc/profile.d/slicPandora.sh

# lcio2hepsim
ADD lcio2hepsim.tar.gz /opt/

RUN cd /opt/lcio2hepsim && \
	sudo chown -R fpadsimuser:fpadsimuser . && \
	make clean && \
	make

# fpadsim
RUN echo 'export FPADSIM=/opt' | sudo bash -c "cat >> /etc/profile.d/fpadsim.sh" && \
	sudo chmod +x /etc/profile.d/fpadsim.sh

# ProMC
RUN sudo pacman -S --noconfirm \
		diffutils \
		pkg-config \
		rsync

ENV PROMC_VERSION 1.6

RUN wget http://atlaswww.hep.anl.gov/asc/promc/download/ProMC-$PROMC_VERSION.tgz -q -O ProMC.tgz && \
	tar -xzf ProMC.tgz && \
	cd ProMC && \
	./build.sh && \
	sed -ibak "s/read yn/yn=y/" install.sh && \
	sudo ./install.sh /usr/local && \
	cd ../ && \
	sudo rm -rf ProMC.tgz ProMC

RUN sudo bash -c 'echo "source /usr/local/promc/setup.sh" > /etc/profile.d/promc.sh' && \
	echo 'promc2lcioBasepath=/usr/local/promc/examples/promc2lcio; export CLASSPATH=$CLASSPATH:${promc2lcioBasepath}:${promc2lcioBasepath}/lib/freehep-mcfio-2.0.1.jar:${promc2lcioBasepath}/lib/lcio-2.4.4-SNAPSHOT-bin.jar:${promc2lcioBasepath}/lib/freehep-xdr-2.0.3.jar:/usr/local/promc/java/promc-protobuf.jar:/usr/local/promc/examples/browser/browser_promc.jar' | \
		sudo bash -c "cat >> /etc/profile.d/promc.sh" && \
	sudo chmod +x /etc/profile.d/promc.sh

# Jas4pp
ENV JAS4PP_VERSION 1.2

RUN wget https://atlaswww.hep.anl.gov/asc/jas4pp/download/jas4pp-$JAS4PP_VERSION.tgz -q -O jas4pp.tgz && \
	tar -xzf jas4pp.tgz -C /opt && \
	rm jas4pp.tgz && \
	sudo bash -c 'echo "source /opt/jas4pp/setup.sh" > /etc/profile.d/jas4pp.sh' && \
	sudo chmod +x /etc/profile.d/jas4pp.sh && \
	/etc/profile.d/jas4pp.sh

# Go
RUN sudo pacman -S --noconfirm \
		go \
		mercurial

ENV GOPATH /opt/Go

RUN mkdir $GOPATH && \
	echo 'export PATH='$GOPATH'/bin:$PATH' | sudo bash -c "cat >> /etc/profile.d/go.sh" && \
	sudo chmod +x /etc/profile.d/go.sh

# go-hep
RUN go get go-hep.org/x/hep/...

# gonum/plot
RUN go get github.com/gonum/plot/...

# Required tools
RUN sudo pacman -S --noconfirm \
		libxtst \
		zip
