//
// Created by makhlu on 22.09.2021.
//

#ifndef YC_SPEECHKIT_TRANSCODER_DISCOVERER_H
#define YC_SPEECHKIT_TRANSCODER_DISCOVERER_H

#include <gst/gst.h>
#include <gst/pbutils/pbutils.h>
#include <gst/pbutils/gstdiscoverer.h>

/* Structure to contain all our information, so we can pass it around */
typedef struct _DiscovererData {
    GstDiscoverer* discoverer;
    GMainLoop* loop;
} DiscovererData;

#endif //YC_SPEECHKIT_TRANSCODER_DISCOVERER_H
