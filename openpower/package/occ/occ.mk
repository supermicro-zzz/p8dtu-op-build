################################################################################
#
# occ
#
################################################################################

OCC_VERSION_BRANCH_MASTER_P8 ?= e6e194f4d9fee9d9a2e9efbc5bd6af1e799b21db
OCC_VERSION_BRANCH_MASTER ?= 64fcfd7e3f3899e761d21eda204b53114d494aaa

OCC_VERSION ?= $(if $(BR2_OPENPOWER_POWER9),$(OCC_VERSION_BRANCH_MASTER),$(OCC_VERSION_BRANCH_MASTER_P8))
OCC_SITE ?= $(call github,open-power,occ,$(OCC_VERSION))
OCC_LICENSE = Apache-2.0

OCC_INSTALL_IMAGES = YES
OCC_INSTALL_TARGET = NO

OCC_STAGING_DIR = $(STAGING_DIR)/occ

OCC_IMAGE_BIN_PATH = $(if $(BR2_OPENPOWER_POWER9),obj/image.bin,src/image.bin)

OCC_DEPENDENCIES_P8 = host-binutils host-p8-pore-binutils
OCC_DEPENDENCIES_P9 = host-binutils host-ppe42-gcc
OCC_DEPENDENCIES ?= $(if $(BR2_OPENPOWER_POWER9),$(OCC_DEPENDENCIES_P9),$(OCC_DEPENDENCIES_P8))

define OCC_APPLY_PATCHES
       if [ "$(BR2_OPENPOWER_POWER9)" == "y" ]; then \
           $(APPLY_PATCHES) $(@D) $(BR2_EXTERNAL)/package/occ/p9Patches \*.patch; \
           if [ -d $(BR2_EXTERNAL)/custom/patches/occ/p9Patches ]; then \
               $(APPLY_PATCHES) $(@D) $(BR2_EXTERNAL)/custom/patches/occ/p9Patches \*.patch; \
           fi; \
       fi; \
       if [ "$(BR2_OPENPOWER_POWER8)" == "y" ]; then \
           $(APPLY_PATCHES) $(@D) $(BR2_EXTERNAL)/package/occ/p8Patches \*.patch; \
           if [ -d $(BR2_EXTERNAL)/custom/patches/occ/p8Patches ]; then \
               $(APPLY_PATCHES) $(@D) $(BR2_EXTERNAL)/custom/patches/occ/p8Patches \*.patch; \
           fi; \
       fi;
endef

OCC_POST_PATCH_HOOKS += OCC_APPLY_PATCHES

define OCC_BUILD_CMDS_P8
        cd $(@D)/src && \
        make POREPATH=$(P8_PORE_BINUTILS_BIN)/bin/ OCC_OP_BUILD=1 CROSS_PREFIX=$(TARGET_CROSS) all && \
        make tracehash && \
        make combineImage
endef
define OCC_BUILD_CMDS_P9
        cd $(@D)/src && \
        make PPE_TOOL_PATH=$(PPE42_GCC_BIN) OCC_OP_BUILD=1 CROSS_PREFIX=$(TARGET_CROSS) LD_LIBRARY_PATH=$(HOST_DIR)/usr/lib all 
endef
OCC_BUILD_CMDS ?= $(if $(BR2_OPENPOWER_POWER9),$(OCC_BUILD_CMDS_P9),$(OCC_BUILD_CMDS_P8))

define OCC_INSTALL_IMAGES_CMDS
       mkdir -p $(STAGING_DIR)/occ
       cp $(@D)/$(OCC_IMAGE_BIN_PATH) $(OCC_STAGING_DIR)/$(BR2_OCC_BIN_FILENAME)
endef

$(eval $(generic-package))
