# Hash19
[![Build Status](https://travis-ci.org/rcdexta/hash19.svg)](https://travis-ci.org/rcdexta/hash19)

![Hash-19](https://s3-us-west-1.amazonaws.com/rcdexta/hash-19-droid.png)

*Hash-19 is as an assassin droid in the Star Wars Universe. These are durasteel drones uploaded with only the most archaic kill programs.*

Ahem.. Ahem.. So about this gem itself.. When I was writing an aggregation API that has to talk to multiple services each with their own REST end-points and when mashing up the JSON payload in a form acceptable to consumer, I ended up writing lot of boiler plate code. I could see patterns and there was clearly scope for optimisation.

Hash19 is an attempt at offering a DSL to tame the JSON manipulation and help in dealing with common use cases. The features include

* whitelisting attributes
* attribute aliasing and keying
* `has_one` and `has_many` associations 
* mass injection of associations using bulk APIs

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'hash19'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hash19

## Usage

### See it all in this example
```ruby
class Jedi
    include Hash19
    attributes :name, :saber, :padawan_id
    attribute :master, key: :trained_by
    has_one :padawan, using: :padawan_id, trigger: ->(id) { Padawan.find id }
    has_many :killings
end
class Padawan
    include Hash19
    attributes :id, :name
    def find(id)..end #implementation hidden
    def find_all(ids)..end #implementation hidden
end

json = '[{"name": "Anakin Skywalker", "saber": "Single Blade Blue",  "trained_by": "Obi Wan",
         "padawan": {"id": 201, "name": "Ahsoka Tano"}},
        {"name": "Mace Windu", "saber": "Single Blade Violet", "padawan_id": 132, "trained_by": "Yoda"}]'
        
jedis = JSON.parse(json)    
Jedi.new(jedis.first).to_h #{"name"=>"Anakin Skywalker", "saber"=>"Single Blade Blue", "master"=>"Obi Wan",
                           #"padawan"=>{"id"=>201, "name"=>"Ahsoka Tano"}}
                           
Jedi.new(jedis.last).to_h #{"name"=>"Mace Windu", "saber"=>"Single Blade Violet", "master"=>"Yoda",
                           #"padawan"=>{"id"=>132, "name"=>"Depa Billaba["}}

```
All aspects of the code are explained with detailed examples below. This gives a quick glance of what can the gem can do. So.
* the attributes `name`, `saber` and `padawan_id` have been whitelisted. Any other attribute in the root of the JSON will be ignored
* the attributes can have aliases in the actual JSON
* there can be an inline relationship within the JSON with anothe entity. For example, each `Jedi` entity can contain a `padawan` object. If the association already exists, it will be transformed.
* All associations are lazy loaded. The first call to the attribute will call the trigger to fetch the association if not present. In this case, a call to `find` method of Padawan will be triggered and the association fetched.

###1. Whitelisting attributes

```ruby
 class SuperHero 
	 include Hash19
	 attributes :name, :strength
	 attribute :universe, key: :comic
 end
 ```
 Assume a JSON payload has many more attribute
 ```json
 [{"name": "Flash", "strength": "Speed", "last_seen": "never", "comic": "DC"},
  {"name": "Magneto", "strength": "Magnetism Control", "first_seen": 1963, "comic": "Marvel"},
  {"name": "Hulk", "strength": "Super Strength", "weakness": "temper", "comic": "Marvel"}]
  ```
  When this JSON is thrown at a Hash19 class...
  ```ruby
    payload = JSON.parse(json)
    results = payload.map { |hash| SuperHero.new(hash).to_h }
    print results #[{"name"=>"Flash", "strength"=>"Speed", "universe"=>"DC"},
                  # {"name"=>"Magneto", "strength"=>"Magnetism Control", "universe"=>"Marvel"},
                  # {"name"=>"Hulk", "strength"=>"Super Strength", "universe"=>"Marvel"}]
  ```
  Note that only the whitelisted attributes are accepted and keys can be aliased. The `to_h` method converts the native hash19 object into a ruby hash. 
  
###2. Still a hash
The Hash19 object acts as a wrapper to Ruby Hash. Till `to_h` is called, all hash operations can be still done on it.
``` ruby
 hero = SuperHero.new(name: "Flash", strength: "Speed", comic: "DC")
 hero[:name] #Flash
 hero[:nick_name] = "Scarlet Speedster"
 hero.keys #["name", "strength", "universe", "nick_name"]
 hero.to_h #{"name"=>"Flash", "strength"=>"Speed", "universe"=>"DC", "nick_name"=>"Scarlet Speedster"}
```
  
  
  
