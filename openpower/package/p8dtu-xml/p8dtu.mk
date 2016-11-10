################################################################################
#
# P8dtu_xml
#
################################################################################
P8DTU_XML_VERSION ?= 27a25e9adfd991813baddb0781615fcb0ed345e5
P8DTU_XML_SITE_METHOD = git
P8DTU_XML_SITE = git@github.com:supermicro/p8dtu-xml.git
#P8DTU_XML_SITE ?= $(call github,open-power,firestone-xml,$(FIRESTONE_XML_VERSION))

P8DTU_XML_LICENSE = Apache-2.0
P8DTU_XML_DEPENDENCIES = hostboot openpower-mrw common-p8-xml

P8DTU_XML_INSTALL_IMAGES = YES
P8DTU_XML_INSTALL_TARGET = YES

MRW_SCRATCH=$(STAGING_DIR)/openpower_mrw_scratch
MRW_HB_TOOLS=$(STAGING_DIR)/hostboot_build_images

# Defines for BIOS metadata creation
BIOS_SCHEMA_FILE = $(MRW_HB_TOOLS)/bios.xsd
P8DTU_BIOS_XML_CONFIG_FILE = $(MRW_SCRATCH)/$(BR2_P8DTU_BIOS_XML_FILENAME)
BIOS_XML_METADATA_FILE = \
    $(MRW_HB_TOOLS)/$(BR2_OPENPOWER_CONFIG_NAME)_bios_metadata.xml
PETITBOOT_XSLT_FILE = $(MRW_HB_TOOLS)/bios_metadata_petitboot.xslt
PETITBOOT_BIOS_XML_METADATA_FILE = \
    $(MRW_HB_TOOLS)/$(BR2_OPENPOWER_CONFIG_NAME)_bios_metadata_petitboot.xml
PETITBOOT_BIOS_XML_METADATA_INITRAMFS_FILE = \
    $(TARGET_DIR)/usr/share/bios_metadata.xml

ifeq ($(BR2_OPENPOWER_SECUREBOOT_ENABLED),y)
ATTRIBUTE_COMPILER_SECUREBOOT_OPT=--secureboot
endif

define P8DTU_XML_BUILD_CMDS
        # copy the P8DTU xml where the common lives
        bash -c 'mkdir -p $(MRW_SCRATCH) && cp -r $(@D)/* $(MRW_SCRATCH)'

        # generate the system mrw xml
        perl -I $(MRW_HB_TOOLS) \
        $(MRW_HB_TOOLS)/processMrw.pl -x $(MRW_SCRATCH)/p8dtu.xml
        
        # merge in any system specific attributes, hostboot attributes
        $(MRW_HB_TOOLS)/mergexml.sh $(MRW_SCRATCH)/$(BR2_P8DTU_SYSTEM_XML_FILENAME) \
            $(MRW_HB_TOOLS)/attribute_types.xml \
            $(MRW_HB_TOOLS)/attribute_types_hb.xml \
            $(MRW_HB_TOOLS)/target_types_merged.xml \
            $(MRW_HB_TOOLS)/target_types_hb.xml \
            $(MRW_SCRATCH)/$(BR2_P8DTU_MRW_XML_FILENAME) > $(MRW_HB_TOOLS)/temporary_hb.hb.xml;

        # creating the targeting binary
        $(MRW_HB_TOOLS)/xmltohb.pl  \
            --hb-xml-file=$(MRW_HB_TOOLS)/temporary_hb.hb.xml \
            --fapi-attributes-xml-file=$(MRW_HB_TOOLS)/fapiattrs.xml \
            --src-output-dir=none \
            --img-output-dir=$(MRW_HB_TOOLS)/ \
            --vmm-consts-file=$(MRW_HB_TOOLS)/vmmconst.h --noshort-enums \
            --bios-xml-file=$(P8DTU_BIOS_XML_CONFIG_FILE) \
            --bios-schema-file=$(BIOS_SCHEMA_FILE) \
            --bios-output-file=$(BIOS_XML_METADATA_FILE) \
 			$(ATTRIBUTE_COMPILER_SECUREBOOT_OPT)

        # Transform BIOS XML into Petitboot specific BIOS XML via the schema
        xsltproc -o \
            $(PETITBOOT_BIOS_XML_METADATA_FILE) \
            $(PETITBOOT_XSLT_FILE) \
            $(BIOS_XML_METADATA_FILE)
endef

define P8DTU_XML_INSTALL_IMAGES_CMDS
        mv $(MRW_HB_TOOLS)/targeting.bin $(MRW_HB_TOOLS)/$(BR2_OPENPOWER_TARGETING_BIN_FILENAME)
	if     [ -n "$(BR2_OPENPOWER_SECUREBOOT_ENABLED)" ] \
			&& [ "$(BR2_OPENPOWER_SECUREBOOT_ENABLED)" == 'y' ]; then \
            mv -v $(MRW_HB_TOOLS)/targeting.bin.protected $(MRW_HB_TOOLS)/$(BR2_OPENPOWER_TARGETING_BIN_FILENAME).protected; \
            mv -v $(MRW_HB_TOOLS)/targeting.bin.unprotected $(MRW_HB_TOOLS)/$(BR2_OPENPOWER_TARGETING_BIN_FILENAME).unprotected; \
	fi
endef

define P8DTU_XML_INSTALL_TARGET_CMDS
        # Install Petitboot specific BIOS XML into initramfs's usr/share/ dir
        $(INSTALL) -D -m 0644 \
            $(PETITBOOT_BIOS_XML_METADATA_FILE) \
            $(PETITBOOT_BIOS_XML_METADATA_INITRAMFS_FILE)
endef

$(eval $(generic-package))
