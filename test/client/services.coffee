define ['services', 'support']
, (
  {Provider, service},
  {should, sinon}
)->

  describe 'services', ->

    Given 'a provider', -> new Provider

    When -> @provider.provide('a', service -> 'no deps')
    When 'service', -> @provider.get('a')
    Then 'service', should.equal('no deps')

    When -> @provider.provide('a', service ['b', 'c'], (b, c)-> [b,c])
    When -> @provider.provide('b', service -> 'b')
    When -> @provider.provide('c', service -> 'c')
    When 'service', -> @provider.get('a')
    Then 'service', should.deep.equal(['b', 'c'])

    When 'init', -> sinon.spy(-> 'a')
    When -> @provider.provide('a', service @init)
    When ->
      @provider.get('a')
      @provider.get('a')
      @provider.get('a')
    Then 'init', sinon.assert.calledOnce
