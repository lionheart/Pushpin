#!/usr/bin/env ruby

require 'spaceship';

Spaceship::Tunes::login("dan@lionheartsw.com")
Spaceship::Tunes.select_team

app_name = "Pushpin"
bundle_identifier = "io.aurora.pushpin"

app = Spaceship::Tunes::Application.find(bundle_identifier)

family = app.in_app_purchases.families.all.first
app.in_app_purchases.create!(
  type: Spaceship::Tunes::IAPType::RECURRING,
  versions: {
    'en-US': {
      name: "Monthly Tip",
      description: "Every little bit counts!."
    },
  },
  reference_name: "Monthly Tip Subscription",
  product_id: "#{bundle_identifier}.TipJarSubscription.Monthly",
  cleared_for_sale: true,
  subscription_duration: '1y'
  # review_screenshot: "/Users/hjanuschka/Desktop/review.jpg", 
  pricing_intervals: [ {
      country: "WW",
      begin_date: nil,
      end_date: nil,
      tier: 1
    }
  ]
)

tips = [
  {
    :name: "Small",
    :description: "",
    :reference_name: "Small Tip",
    :product_id: "com.lionheartsw.Pushpin.Tip.Small",
    :tier: 1
  },
  {
    :name: "Medium",
    :description: "",
    :reference_name: "Medium Tip",
    :product_id: "com.lionheartsw.Pushpin.Tip.Medium",
    :tier: 2
  },
  {
    :name => "Large",
    :description => "",
    :reference_name => "Large Tip",
    :product_id => "com.lionheartsw.Pushpin.Tip.Large",
    :tier => 5
  },
  {
    :name => "Huge",
    :description => "",
    :reference_name => "Huge Tip",
    :product_id => "com.lionheartsw.Pushpin.Tip.Huge",
    :tier => 10
  },
  {
    :name => "Massive",
    :description => "I don't even know what to say. I'm incredibly grateful for your generosity.",
    :reference_name => "Massive Tip",
    :product_id => "com.lionheartsw.Pushpin.Tip.Massive",
    :tier => 20
  }
]

# TODO
#  review_notes: "Some Review Notes here bla bla bla",
#  review_screenshot: "/Users/dan/Desktop/Simulator Screen Shot - iPhone 8 - 2017-10-20 at 19.20.25.png",

tips.each { |tip|
  app.in_app_purchases.create!(
    type: Spaceship::Tunes::IAPType::CONSUMABLE,
    versions: {
      'en-US': {
        name: tip[:name],
        description: tip[:description]
      },
    },
    reference_name: tip[:reference_name],
    product_id: tip[:product_id],
    cleared_for_sale: true,
    pricing_intervals: [
      {
        country: "WW",
        begin_date: nil,
        end_date: nil,
        tier: tip[:tier]
      }
    ]
  )
}


app.in_app_purchases.create!(
  type: Spaceship::Tunes::IAPType::CONSUMABLE,
  versions: {
    'en-US': {
      name: "Medium",
      description: "You rock! Thanks for chipping in."
    },
  },
  reference_name: "Medium Tip",
  product_id: "com.lionheartsw.Pushpin.Tip.Medium",
  cleared_for_sale: true,
  pricing_intervals: [
      {
        country: "WW",
        begin_date: nil,
        end_date: nil,
        tier: 2
      }
    ]
)
