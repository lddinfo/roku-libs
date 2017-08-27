APPNAME = roku-libs
VERSION ?= 0.3.0
IP ?= 192.168.1.1
USERNAME ?= rokudev
USERPASS ?= password
ZIP_EXCLUDE = -x \*.pkg -x keys\* -x LICENSE\* -x \*.md -x \*/.\* -x .\* -x build\* -x package\*
PKGREL = ./package
ZIPREL = ./build
SOURCEREL = ..

.PHONY: zip install remove tests package

zip:
# Remove old application zip
	@if [ -e "$(ZIPREL)/$(APPNAME).zip" ]; \
	then \
		rm  $(ZIPREL)/$(APPNAME).zip; \
	fi

# Create destination directory	
	@if [ ! -d $(ZIPREL) ]; \
	then \
		mkdir -p $(ZIPREL); \
	fi

# Set directory permissions
	@if [ ! -w $(ZIPREL) ]; \
	then \
		chmod 755 $(ZIPREL); \
	fi

# Zip .png files without compression do not zip Makefiles or any files ending with '~'
	@echo "    Creating application zip: $(ZIPREL)/$(APPNAME).zip"	
	@if [ -d $(SOURCEREL)/$(APPNAME) ]; \
	then \
		(zip -q -0 -r "$(ZIPREL)/$(APPNAME).zip" . -i \*.png $(ZIP_EXCLUDE)); \
		(zip -q -9 -r "$(ZIPREL)/$(APPNAME).zip" . -x \*~ -x \*.png -x Makefile $(ZIP_EXCLUDE)); \
	else \
		echo "    Source for $(APPNAME) not found at $(SOURCEREL)/$(APPNAME)"; \
	fi

install: zip
# Close current app to avoid crashes
	@curl -d "" "http://$(IP):8060/keypress/home"
	@sleep 1

	@echo "    Installing $(APPNAME).zip to host $(IP)"
	@curl --user $(USERNAME):$(USERPASS) --digest -s -S -F "mysubmit=Install" -F "archive=@$(ZIPREL)/$(APPNAME).zip" -F "passwd=" http://$(IP)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[[" ; \

remove:
# Close current app to avoid crashes
	@curl -d "" "http://$(IP):8060/keypress/home"
	@sleep 1

	@echo "    Removing $(APPNAME) from host $(IP)"
	@curl --user $(USERNAME):$(USERPASS) --digest -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(IP)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[[" ; \

tests: install
	@echo "    Running tests at $(IP)"
	@curl -d '' "http://${IP}:8060/launch/dev?RunTests=true"

package: DEVIDPASS ?= "$(shell read -p "    Developer ID password: " REPLY; echo $$REPLY)"
package: install
# Create destination directory
	@if [ ! -d $(PKGREL) ]; \
	then \
		mkdir -p $(PKGREL); \
	fi

# Set directory permissions
	@if [ ! -w $(PKGREL) ]; \
	then \
		chmod 755 $(PKGREL); \
	fi

# Package application on remote device
	@echo "    Packaging $(APPNAME) to host $(IP)"
	$(eval PKGFILE := $(shell curl --anyauth -u $(USERNAME):$(USERPASS) -s -S -Fmysubmit=Package -Fapp_name=$(APPNAME)/$(VERSION) -Fpasswd=$(DEVIDPASS) -Fpkg_time=`date +%s` "http://$(IP)/plugin_package" | grep 'pkgs' | sed 's/.*href=\"\([^\"]*\)\".*/\1/' | sed 's#pkgs//##'))
	@if [ -z $(PKGFILE) ]; \
	then \
		echo "    Package creation failed! Check if your device has been rekeyed"; \
		exit 1; \
	fi

# Dowload package from device
	$(eval PKGFULLPATH := $(PKGREL)/$(APPNAME)-$(VERSION)_$(PKGFILE))
	@curl --user $(USERNAME):$(USERPASS) --digest -s -S -o $(PKGFULLPATH) http://$(IP)/pkgs/$(PKGFILE)
	@if [ ! -f ""$(PKGFULLPATH)"" ]; \
	then \
		echo "    Package download failed! File does not exist: $(PKGFULLPATH)"; \
		exit 2; \
	fi
	@echo "    Package downloaded to: $(PKGFULLPATH)"
