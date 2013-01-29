
Session.set("symptoms", [])

Meteor.Router.add
    '/': 'home'
    '/suggest': 'suggest'
    '/patients': 'patients'
    '/library': 'library'

Template.nav.isActive = (pageName) ->
    Meteor.Router.page() == pageName

Template.suggest.events
    "click .reltag": (e, template) ->
        template.t.add $(e.currentTarget).text()
    "click .diseaseRow": (e, template) ->
        Session.set "diseaseName", $(e.currentTarget).data("name")
        Session.set "showDiseaseDialog", true


Template.suggest.rendered = ->
    return if @t?
    Session.set "symptoms", []
    Session.set "showDiseaseDialog", false
    @t = new $.TextboxList ".symptoms-input", 
        bitsOptions: 
            editable: 
                addDecoded: true  # Use enter or comma to delimit tags
                addOnBlur: true
        unique: true
        uniqueInsensitive: true

    @t.addEvent 'bitAdd', (bit) =>
        Session.set "symptoms", @t.getValues().map (t)->t[1]
    
    @t.addEvent 'bitRemove', (bit) =>
        Session.set "symptoms", @t.getValues().map (t)->t[1]

Template.suggest.showDiseaseDialog = ->
    Session.get "showDiseaseDialog"

Template.diseaseDialog.events
    "click .close": ->
        Session.set "showDiseaseDialog", false

Template.diseaseDialog.diseaseName = ->
    Session.get "diseaseName"

# == Main tasks ================================================================

diseases = 
    "Bronchitis": "cough,mucus,sore-chest,fatigue,headache,body-ache,fever,watery-eyes,sore-throat"
    "Sinusitis": "headache,nasal-congestion,sore-throat,fever,cough,fatigue,bad-breath"
    "Sore Throat": "sore-throat,sneezing,cough,watery-eyes,headache,body-ache,runny-nose,fever"
    "Acute otitis media": "pulling-at-ears,excessive-crying,fluid-from-ears,sleep-disturbances,fever,headache,hearing-problems,irritability"
    "Common cold": "sneezing,runny-nose,stuffy-nose,sore-throat,cough,watery-eyes,headache,body-ache"

symptoms = {}

for name in Object.keys(diseases)
    sympArr = diseases[name].split(",")
    sympObj = {}
    for symp in sympArr
        symptoms[symp] = true
        sympObj[symp] = true
    
    diseases[name] = 
        total: sympArr.length
        symptoms: sympObj

suggestDiseases = ->
    sym = Session.get "symptoms"
    if sym.length == 0 then return []
    
    arr = []
    for name, dis of diseases
        prob = sym.map((s)->if dis.symptoms[s] then 1 else -1).reduce(((acc,n)->acc+n),0)
        prob /= sym.length
        if sym.length < 4
            prob /= (4-sym.length) # Confidence.
        arr.push {prob, name}

    arr.sort (a,b)-> -(a.prob-b.prob)
    arr


Template.suggest.relatedTags = ->
    existingTags = {}
    for s in Session.get "symptoms"
        existingTags[s] = true

    tags = {}
    arr = suggestDiseases()
    for d in arr
        for sym of diseases[d.name].symptoms
            tags[sym] ?= 0
            tags[sym] += d.prob/diseases[d.name].total

    tagsArr = ({sym, prob} for sym, prob of tags)
    tagsArr.sort((a,b) -> -(a.prob - b.prob))
    tagsArr.filter((t)->t.prob > 0 and not existingTags[t.sym]).map((t)->t.sym)


Template.suggest.suggestedDiseases = ->
    arr = suggestDiseases()
    arr = arr.filter (dis) -> dis.prob > 0.1
    for a in arr
        a.prob = 0.8*a.prob + 0.1
        a.probability = (a.prob*100).toFixed()

    if arr.length > 0
        return arr
    else 
        return







