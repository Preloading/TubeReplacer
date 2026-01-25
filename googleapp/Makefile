TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TubeReplacerGoogle

TubeReplacerGoogle_FILES = polyfill.x \
	signin.x \
	categories.x \
	deviceauth.x \
	frontfeed.x \
	parsing.x \
	getvideo.x \
	channels.x \
	channelfeed.x \
	search.x \
	feeds.x \
	myprofile.x \
	subscriptions.x \
	homefeed.x \
	suggestedvideos.x \
	comments.x \
	accountfeeds.x \
	playlist.x \
	likes.x \
	Translators/TRJSONUtils.m \
	Translators/TRJSONTranslator.m \
	Translators/TRContiunation.m \
	Translators/Delegates/TRVideoTranslator.m \
	Translators/Delegates/TRChannelTranslator.m \
	Translators/Delegates/TRFeedTranslator.m \
	Translators/Delegates/TRCommentTranslator.m \
	Translators/Delegates/TRSubscriptionTranslator.m \
	Translators/Delegates/TRPlaylistTranslator.m \
	Translators/Delegates/TRYTStreamDetails.m \
	Translators/TRRequestBuilder.m \
	../Protobuf.m ../YoutubeClientType.m general.m ../base64/NSData+Base64.m ../base64/NSString+Base64.m
	
TubeReplacerGoogle_CFLAGS = -fno-objc-arc -ITranslators

before-all::
	rm signinpolyfil.h
	xxd -i signinpolyfil.js > signinpolyfil.h

include $(THEOS_MAKE_PATH)/tweak.mk
