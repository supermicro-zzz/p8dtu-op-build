################################################################################
#
#  sb-signing-utils
#
################################################################################

SB_SIGNING_UTILS_SITE ?= $(call github,bofferdn,sb-signing-utils,$(SB_SIGNING_UTILS_VERSION))
SB_SIGNING_UTILS_VERSION ?= 037cc2bdcdef45cf446364b637a7b3eeba79c4b3

SB_SIGNING_UTILS_LICENSE = Apache-2.0
SB_SIGNING_UTILS_LICENSE_FILES = LICENSE

HOST_SB_SIGNING_UTILS_DEPENDENCIES = host-openssl host-perl-convert-pem

HOST_SB_SIGNING_UTILS_AUTORECONF = YES

ifdef ALT_HOST_TOOLCHAIN_CXX
HOST_SB_SIGNING_UTILS_CONF_ENV=CXX=$(ALT_HOST_TOOLCHAIN_CXX)
endif

SB_SIGNING_UTILS_KEY_SRC_PATH=$(BR2_EXTERNAL)/package/sb-signing-utils/keys
SB_SIGNING_UTILS_KEY_DST_PATH=$(HOST_DIR)/etc/keys

define COPY_KEYS_TO_DESTINATION
	$(INSTALL) -d -m 0755 $(SB_SIGNING_UTILS_KEY_DST_PATH)
	$(INSTALL) -m 0755 $(SB_SIGNING_UTILS_KEY_SRC_PATH)/* \
		$(SB_SIGNING_UTILS_KEY_DST_PATH)
endef

HOST_SB_SIGNING_UTILS_POST_INSTALL_HOOKS += COPY_KEYS_TO_DESTINATION

$(eval $(host-autotools-package))
