import 'package:flutter/material.dart';
import 'wifi_view.dart';
import 'wifi_network.dart';
import 'enum.dart';
import 'root_funcs.dart';
import 'dart:async';
import 'app.dart';
import 'dart:io';
import 'package:share/share.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';


void main() {
  // This will ONLY work on Android
    App.initPlatformState().then((_)  {
      runApp(new WiFiKeyRecovery());
   });
}

class WiFiKeyRecovery extends StatelessWidget {
  // Main Application Class
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'WiFi Key Recovery (root)',
      theme: new ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: new NetworkListPage(title: 'WiFi Key Recovery (root)'),
    );
  }
}

class NetworkListPage extends StatefulWidget {
  NetworkListPage({Key key, this.title}) : super(key: key);
  final String title;
  //Widget appBarTitle = new Text("WiFi Key Recover (root)");

  @override
  NetworkListPageState createState() => new NetworkListPageState();

  static NetworkListPageState of(BuildContext context) =>
    context.ancestorStateOfType(const TypeMatcher<NetworkListPageState>());

}

class NetworkListPageState extends State<NetworkListPage> {
  final GlobalKey _scaffoldKey = new GlobalKey();
  
  // Main page containing list of networks
  String _searchText = ""; // network name filter
  List<Widget> _networkList = []; // list of networks. This should only be updated once
  final ScrollController _scrollController = new ScrollController(); // So we can scroll to the current SSID when the program starts
  List<NetworkListItem> _selectedNetworks = [];
  bool _clearingSelection = false;
  
  // Pieces to have the search at the top
  final TextEditingController _searchQuery = new TextEditingController();
  static Widget _appBarTitle = Text("WiFi Key Recovery (root)");
  static Icon _searchIcon = new Icon(Icons.search, color: Colors.white,);
  

  NetworkListPageState(){
    _buildNetworkList();
    // Handle what happens when text is entered in the search bos
    _searchQuery.addListener(() {
      if (_searchQuery.text.isEmpty) {
        setState(() {
          _searchText = "";
        });
      }
      else {
        setState(() {
          _searchText = _searchQuery.text;
        });
      }
    });
  }

  @override
  void initState(){
    super.initState();
    // We're going to scroll to current SSID after the page finishes rendering
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNetwork(context));
    
  }
  /// Add a wifi network to the SELECTED list
  void addSelection(NetworkListItem item){
    _selectedNetworks.add(item);
    setState(() {
      _buildAppBarTitle();
    });
  }
  /// Remove a wifi network from the SELECTED list
  void removeSelection(NetworkListItem item){
    if (_clearingSelection)
      return;
    _selectedNetworks.removeWhere((n) => n.key == item.key);
    setState(() {
      _buildAppBarTitle();
    });
  }
  /// Completely clear all selected networks
  void _clearSelections(){
    // make sure we don't trigger a SetState in the middle of our SetState
    _clearingSelection = true;
    setState(() { 
      _selectedNetworks.clear(); 
      _buildAppBarTitle();

      // Tried all of these combinations, no luck getting the ListTiles to rebuild      
      //_scaffoldKey.currentState.context.visitChildElements((v) => v.markNeedsBuild());
      //_scaffoldKey.currentState.context.visitChildElements((v) =>() {v.markNeedsBuild();});
      //_scaffoldKey.currentState.context.visitChildElements((v) =>(_) {v.markNeedsBuild();});
      //_scaffoldKey.currentState.context.visitChildElements((v) {v.markNeedsBuild();});
      //_scaffoldKey.currentState.reassemble();
      // Haven't found a better way to force all the ListTiles to rebuild
      WidgetInspectorService.instance.forceRebuild();
    });
    _clearingSelection = false;

  }
  /// Check if ssid is in the selected network list
  bool checkSelected(String ssid){
    if (_selectedNetworks.length == 0)
      return false;
    if (_selectedNetworks.where((n) => n.wifi.ssid == ssid).length > 0)
      return true;
    return false;
  }
  bool isSelecting(){
    return (_selectedNetworks.length > 0);
  }
  /// Finds the pixel in the list to scroll to
  double _findScrollPosition(String ssid){
    // 
    // Fall back to 0 if the SSID is not found - bump to the top of the list
    int scrollIndex = 0;
    // Go through the children and compare the keys to find the index number of this SSID
    if (_networkList[0].runtimeType == NetworkListItem){
      for (int i = 0; i < _networkList.length - 1;i++){
        if ((_networkList[i] as NetworkListItem).wifi.ssid == ssid){
          scrollIndex = i;
          break;
        }
      }
    }
    // Get total size of scrollable list
    double totalSize = _scrollController.position.extentAfter + _scrollController.position.extentBefore + _scrollController.position.extentInside;
    // Get the size (height) of each tile - they should all be the same.
    double tileSize = 1.0;
    if (_networkList.length > 0)
       tileSize = totalSize / _networkList.length;
    // Ffind the position inside the total size to which we want to scroll
    double scrollTo =  tileSize * scrollIndex;
    // If we're trying to scroll outside the list, just scroll to maxScrollExtent
    if (scrollTo > _scrollController.position.maxScrollExtent)
      return _scrollController.position.maxScrollExtent;
    else
      return scrollTo;
  }

  /// Scrolls to the current SSID. Should only be called once, but can be called again if necessary
  void _scrollToNetwork(BuildContext context){
    // Do not scroll if the page has an error like 'Requires Root'
    if (_networkList.first.runtimeType == Text){
      return;
    }
    // let's wait a half second after the list is loaded (and this is called) before trying to scroll.
     Future.delayed(
          const Duration(milliseconds: 500),
          () => _scrollController.animateTo(
            _findScrollPosition(getSSID()), 
            duration: new Duration(seconds:1),
            curve:  Curves.ease
          ),
      );
    
  }
  @override
  Widget build(BuildContext context) {
    List<Widget> tmpList = _networkList.where((l) => l.key.toString().toUpperCase().contains(_searchText.toUpperCase())).toList();
    if (tmpList.length == 0){
      tmpList =  [ new Text("No Matches Found", textScaleFactor: 2.0,)];
    }
    String scrollLetter = "";
    int currentItem = 0;

       return new Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(context),
        body: DraggableScrollbar.semicircle(
          backgroundColor: Colors.cyanAccent,
          controller: _scrollController,
          labelTextBuilder: (offset) {
            if (_scrollController.hasClients){
              if ((_scrollController.position.maxScrollExtent *  (tmpList.length - 1 )) == 0 ) {
                currentItem = 0;
              }else {
                currentItem = (_scrollController.offset / _scrollController.position.maxScrollExtent * (tmpList.length - 1 )).floor();
              }
            }
            if (tmpList[currentItem].runtimeType == NetworkListItem){
              scrollLetter = (tmpList[currentItem] as NetworkListItem).wifi.ssid.substring(0,1).toUpperCase();
            }else {
              scrollLetter = "";
            }
            
            return Text(scrollLetter);
          },
          child: new ListView.builder(
            itemCount: tmpList.length,
            controller: _scrollController,
            itemBuilder: (context, index){
              return tmpList[index];
            },
          ),
        )
//        floatingActionButton: new FloatingActionButton(
//          onPressed: debugButton,
//          tooltip: 'Debug',
//          child: new Icon(Icons.details),
//        ), 
    );
  }

  /// We should only call this once, but it will check to make sure we're root and get the networks
  void _buildNetworkList(){
    this._networkList = [];
    // ONLY ANDROID
    if (!Platform.isAndroid){
      this._networkList = [ new Text("Android required", textScaleFactor: 5.0,)];
      return;
    }
    // Will not work without root
    if (!checkRoot()){
      this._networkList = [new Text("Root Required", textScaleFactor: 5.0,)];
      return;
    }
    // We need to change this to check which level OS and call a different helper for earlier releases
    if (!checkVersion(need: "8.0.0", have: App.androidVersion)){
      _networkList = [new Text("Need to have version " + App.androidVersion, textScaleFactor: 2.0,)];
      return;
    }
    // add the check to see which helper we need to call
    List<WiFiNetwork> _tmpnetworkList = readWiFIConfigurationOreo();
    
    // We don't care about the NONE encryptions
    _tmpnetworkList.where((n) => n.encryption != EncryptionType.None).forEach((net) => _networkList.add(new NetworkListItem(net)));
    // If we change our mind and care about NONE, then we can switch to this
    //_networkList.forEach((net) => _buildNetworkList.add(new NetworkListItem(net)));

    _networkList.sort((Widget a,Widget b) =>  a.key.toString().toUpperCase().compareTo(b.key.toString().toUpperCase()));
  }
  
  /// Build the AppBar based on search & selection
  Widget _buildAppBar(BuildContext context){
    List<Widget> actionWidgets = [];
    actionWidgets.add(
         IconButton(icon: _searchIcon, onPressed: () {
          setState(() {
            if (_searchIcon.icon == Icons.search) {
              _handleSearchStart(); 
            } else{
              _handleSearchEnd();
            }
          });
        },)
    );
    if (_selectedNetworks.length > 0){
      actionWidgets.add(
        IconButton(icon: new Icon(Icons.share), onPressed: () { _handleShare();},)
      );
    }

    return new AppBar(
      leading: (_selectedNetworks.length > 0 ?
                new IconButton(icon: new Icon(Icons.cancel), onPressed: () { _clearSelections();},)
                : null
                ),
      title: _appBarTitle, 
      actions: actionWidgets,
    );
  }
  /// Build the AppBar.title based on search & selection
  void _buildAppBarTitle(){
    if (_searchIcon.icon == Icons.close){
      _appBarTitle = new TextField(
        autofocus: true,
        controller: _searchQuery,
        style: new TextStyle(
          color: Colors.white,
        ),
        decoration: new InputDecoration(
          prefixIcon: new Icon(Icons.search, color: Colors.white),
          hintText: "Search...",
          hintStyle: new TextStyle(color: Colors.white)
        ),
      );
    } else {
      if(_selectedNetworks.length == 0){
        _appBarTitle = new Text("WiFi Key Recovery (root)");
      }else {
        _appBarTitle = new Text(_selectedNetworks.length.toString());
      }  
    }
  }
  /// Handles when Share icon is pressed
  _handleShare(){
    String shareString = "";
    for (int i = 0; i < _selectedNetworks.length; i++){
      shareString += _selectedNetworks[i].wifi.ssid + "\r\n" + _selectedNetworks[i].wifi.wifiKey + "\r\n\r\n";
    }
    Share.share(shareString);
  }
  /// Handles when Search icon is pressed. This doesn't handle the actual search.
  void _handleSearchStart(){
    _searchIcon = new Icon(Icons.close, color: Colors.white,);
    _buildAppBarTitle();
  }
  /// Handles when Search is cancelled.
  void _handleSearchEnd(){
    _searchIcon = new Icon(Icons.search, color: Colors.white,);
    _buildAppBarTitle();
    _searchQuery.clear();
  }

//  void _debugButton() {
  //  setState(() {
  //    _searchText = "";
  //  });
//  _scrollController.animateTo(
//            _findScrollPosition(getSSID()), 
//            duration: new Duration(seconds:1),
//            curve:  Curves.ease
//          );
//  }

}
