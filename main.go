package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	log "github.com/sirupsen/logrus"
	"github.com/slack-go/slack"
)

var (
	publicChannelsTotal = prometheus.NewGauge(prometheus.GaugeOpts{
		// TODO: implement parameterised support
		//Namespace: "foo",
		//Subsystem: "bar",
		Name: "slack_channels_public_total",
		Help: "The total number of public channels in the slack workspace",
	})

	token = os.Getenv("SLACK_TOKEN")
)

func getChannelCount() (total int, err error) {
	var count = 0
	api := slack.New(token)

	channels, _, err := api.GetConversations(&slack.GetConversationsParameters{Limit: 1000})
	if err != nil {
		fmt.Printf("%s\n", err)
		return 0, err
	}
	for k, _ := range channels {
		log.Debug(k)
		count++
	}

	return count, nil
}

func recordMetrics() {
	channelCount, err := getChannelCount()
	if err != nil {
		log.Fatal(err)
	}
	publicChannelsTotal.Set(float64(channelCount))
}

func main() {
	prometheus.MustRegister(publicChannelsTotal)
	prometheus.Unregister(prometheus.NewGoCollector())
	recordMetrics()
	http.Handle("/metrics", promhttp.Handler())
	http.ListenAndServe(":2112", nil)
}
