define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  bootstrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'backbone-forms'
  forms_bstrap= require 'forms_bootstrap'
  forms_list  = require 'forms_list'
  forms_custom  = require 'forms_custom'
  
  
  s_template  = require "text!./settings.tmpl"
  sh_template = require "text!./settingsHeader.tmpl"
  sha_template = require "text!./settingsHeaderAll.tmpl"
  sc_template = require "text!./settingsContent.tmpl"
  sca_template = require "text!./settingsContentAll.tmpl"
  
  reqRes = require 'modules/core/reqRes'#request response system , see backbone marionnette docs
  
  
  class SettingsView extends Backbone.Marionette.Layout
    template: s_template
    regions: 
      tabHeaders: "#tabHeaders"
      tabContent: "#tabContent"
    ui:
      tabHeaders: "#tabHeaders"
      tabContent: "#tabContent"
    events:
      "mouseup .applySettings": "applySettings"
      
    applySettings:(ev)=>
      for index, form of @tabContent.currentView.forms
        form.commit({ validate: true })
      @model.save()
    
    constructor:(options) ->
      super options
    
    onRender:()=>
      #show tab nav
      sHeaderView = new SettingHeader
        collection: @model
      @tabHeaders.show sHeaderView
      #show tab panes
      sContentView = new SettingContent
        collection: @model
        
      @tabContent.show sContentView

      $(@ui.tabHeaders).find('li:first').addClass('active')
      defaultItem = $(@ui.tabContent).find('div .tab-pane:first')
      defaultItem.addClass('active')
      defaultItem.removeClass('fade')
 
  #-------------------------------------------------------------------#   

  class SettingHeaderItemView extends Backbone.Marionette.ItemView
    template: sh_template
    tagName: "li"
  
  
  class SettingHeader extends Backbone.Marionette.CompositeView
    itemView: SettingHeaderItemView
    tagName: "ul"
    template: sha_template
    itemViewContainer: "#settingsHeaderUl"
    ui:
      globalContainer: "#settingsHeaderUl"
    
    constructor:(options) ->
      super options
      
    onRender:()=>
      $(@ui.globalContainer).find('li:first').tab('show')


  class SettingContentItemView extends Backbone.Marionette.ItemView
    template: sc_template
    
    onRender:()=>
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
    
  class SettingContent extends Backbone.Marionette.CompositeView
    itemView: SettingContentItemView
    template: sca_template
    itemViewContainer: "#settingsContentAll"
    
    constructor:(options) ->
      super options
      @forms = []
      @specificViews =   
        "GeneralSettings":  GeneralSettingsWrapper
        "KeyBindings"   :   KeyBindingsWrapper

    getItemView: (item) =>
      view = SettingContentItemView
      if item?
        try
          if @specificViews.hasOwnProperty(item.constructor.name)
            view = @specificViews[item.constructor.name]
          else
            #here we send a "request/response to get the correct view (decoupling)"
            name = item.get("name")
            view = reqRes.request("#{name}SettingsView")
        catch error 
          console.log "error: #{error}"
      return view
        
    onRender:()=>
      for index, childView of @children._views
        if childView.wrappedForm?
          @forms.push(childView.wrappedForm)
 
 
  class GeneralSettingsForm extends Backbone.Form

    constructor:(options)->
      if not options.schema
        options.schema=
          csgCompileMode: 
            title: "Compile trigger mode"
            type: 'Select'
            options : ["onDemand", "onCodeChange", "onCodeChangeDelayed", "onSave"]
          csgCompileDelay:
            type: 'Number'
          csgBackgroundProcessing:
            type: 'Checkbox'
          maxRecentFilesDisplay: 
            type:'Number'
            title: 'Max recent files to display'
          
          autoReloadLastProject:
            type:'Checkbox'
            title: 'Reload last project on application start'
            
          theme:
            type:'Select'
            options : ["slate", "spacelab"]
        options.fieldsets=[
          "legend": "CSG compiling settings"
          "fields": ["csgCompileMode","csgCompileDelay","csgBackgroundProcessing"]
        ,
          "legend": "Save and load"
          "fields":["autoReloadLastProject"]
        , 
          "legend":"Other settings"
          "fields": ["maxRecentFilesDisplay","theme"]
          
        ]
      super options
      
  class GeneralSettingsWrapper extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new GeneralSettingsForm
        model: @model
    
    onDomRefresh:=>
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
    
    render:()=>
      @isClosed = false
      @triggerMethod("before:render", @)
      @triggerMethod("item:before:render", @)
  
      tmp = @wrappedForm.render()
      @$el.html(tmp.el)
      @$el.attr('id',@model.get("name"))
      
      @bindUIElements()
      @triggerMethod("render", @)
      @triggerMethod("item:rendered", @)
      return @
      
      
  class KeybindingsForm extends Backbone.Form
    
    constructor:(options)->
      bla=(obj)->
        console.log obj
        return #{obj}
      if not options.schema
        options.schema = 
          #toto: 'CustomEditor'
          notes:
            type: "List"
            listType: 'Text'
            #itemType: 'Select', options:["toto","tata"]
            itemToString: (object)-> console.log(object)
            #listTemplate: 
          general:
            type: "Object"
            title:''
            subSchema:
              undo:
                title:"undo"
                type:"Text"
              redo:
                title:"redo"
                type:"Text"
      super options
      
  class KeyBindingsWrapper extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new KeybindingsForm
        model: @model
       
    render:()=>
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
      return @el    
 
  return SettingsView