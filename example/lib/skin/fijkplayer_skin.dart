// ignore_for_file: must_call_super, camel_case_types
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:fijkplayer_ijkfix/fijkplayer_ijkfix.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

import './schema.dart' show VideoSourceFormat;
import './slider.dart' show NewFijkSliderColors, NewFijkSlider;

double speed = 1.0;
bool lockStuff = false;
bool hideLockStuff = false;
final double barHeight = 50.0;
final double barFillingHeight =
    MediaQueryData.fromWindow(window).padding.top + barHeight;
final double barGap = barFillingHeight - barHeight;

abstract class ShowConfigAbs {
  late bool nextBtn;
  late bool speedBtn;
  late bool drawerBtn;
  late bool lockBtn;
  late bool topBar;
  late bool autoNext;
  late bool bottomPro;
  late bool stateAuto;
  late bool isAutoPlay;
}

class WithPlayerChangeSource {}

String _duration2String(Duration duration) {
  if (duration.inMilliseconds < 0) return "-: negtive";

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  int inHours = duration.inHours;
  return inHours > 0
      ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
      : "$twoDigitMinutes:$twoDigitSeconds";
}

class CustomFijkPanel extends StatefulWidget {
  final FijkPlayer player;
  final Size viewSize;
  final Rect texturePos;
  final BuildContext? pageContent;
  final String playerTitle;
  final Function? onChangeVideo;
  final int curTabIdx;
  final int curActiveIdx;
  final ShowConfigAbs showConfig;
  final VideoSourceFormat? videoFormat;

  CustomFijkPanel({
    required this.player,
    required this.viewSize,
    required this.texturePos,
    this.pageContent,
    this.playerTitle = "",
    required this.showConfig,
    this.onChangeVideo,
    required this.videoFormat,
    required this.curTabIdx,
    required this.curActiveIdx,
  });

  @override
  _CustomFijkPanelState createState() => _CustomFijkPanelState();
}

class _CustomFijkPanelState extends State<CustomFijkPanel>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  FijkPlayer get player => widget.player;
  ShowConfigAbs get showConfig => widget.showConfig;
  VideoSourceFormat get _videoSourceTabs => widget.videoFormat!;

  bool _lockStuff = lockStuff;
  bool _hideLockStuff = hideLockStuff;
  bool _drawerState = false;
  Timer? _hideLockTimer;

  FijkState? _playerState;
  bool _isPlaying = false;

  StreamSubscription? _currentPosSubs;

  AnimationController? _animationController;
  Animation<Offset>? _animation;
  late TabController _tabController;

  void initEvent() {
    _tabController = TabController(
      length: _videoSourceTabs.video!.length,
      vsync: this,
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    // init animation
    _animation = Tween(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(_animationController!);
    // is not null
    if (_videoSourceTabs.video!.length < 1) return null;
    // init plater state
    setState(() {
      _playerState = player.value.state;
    });
    if (player.value.duration.inMilliseconds > 0 && !_isPlaying) {
      setState(() {
        _isPlaying = true;
      });
    }
    // is not null
    if (_videoSourceTabs.video!.length < 1) return null;
    // autoplay and existurl
    if (showConfig.isAutoPlay && !_isPlaying) {
      int curTabIdx = widget.curTabIdx;
      int curActiveIdx = widget.curActiveIdx;
      changeCurPlayVideo(curTabIdx, curActiveIdx);
    }
    player.addListener(_playerValueChanged);
    Wakelock.enable();
  }

  @override
  void initState() {
    super.initState();
    initEvent();
  }

  @override
  void dispose() {
    _currentPosSubs?.cancel();
    _hideLockTimer?.cancel();
    player.removeListener(_playerValueChanged);
    _tabController.dispose();
    _animationController!.dispose();
    Wakelock.disable();
    super.dispose();
  }

  // ?????????????????????
  void _playerValueChanged() {
    if (player.value.duration.inMilliseconds > 0 && !_isPlaying) {
      setState(() {
        _isPlaying = true;
      });
    }
    setState(() {
      _playerState = player.value.state;
    });
  }

  // ??????UI ????????????????????????
  void changeDrawerState(bool state) {
    if (state) {
      setState(() {
        _drawerState = state;
      });
    }
    Future.delayed(Duration(milliseconds: 100), () {
      _animationController!.forward();
    });
  }

  // ??????UI lock????????????
  void changeLockState(bool state) {
    setState(() {
      _lockStuff = state;
      if (state == true) {
        _hideLockStuff = true;
        _cancelAndRestartLockTimer();
      }
    });
  }

  // ???????????????
  Future<void> changeCurPlayVideo(int tabIdx, int activeIdx) async {
    // await player.stop();
    await player.reset().then((_) {
      String curTabActiveUrl =
          _videoSourceTabs.video![tabIdx]!.list![activeIdx]!.url!;
      player.setDataSource(
        curTabActiveUrl,
        autoPlay: true,
      );
      // ??????
      widget.onChangeVideo!(tabIdx, activeIdx);
    });
  }

  void _cancelAndRestartLockTimer() {
    if (_hideLockStuff == true) {
      _startHideLockTimer();
    }
    setState(() {
      _hideLockStuff = !_hideLockStuff;
    });
  }

  void _startHideLockTimer() {
    _hideLockTimer?.cancel();
    _hideLockTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _hideLockStuff = true;
      });
    });
  }

  // ??? ??????
  Widget _buidLockStateDetctor() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _cancelAndRestartLockTimer,
      child: Container(
        child: AnimatedOpacity(
          opacity: _hideLockStuff ? 0.0 : 0.7,
          duration: Duration(milliseconds: 400),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                top: showConfig.stateAuto && !player.value.fullScreen
                    ? barGap
                    : 0,
              ),
              child: IconButton(
                iconSize: 30,
                onPressed: () {
                  setState(() {
                    _lockStuff = false;
                    _hideLockStuff = true;
                  });
                },
                icon: Icon(Icons.lock_open),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ????????????
  Widget _buildTopBackBtn() {
    return Container(
      height: barHeight,
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: Icon(Icons.arrow_back),
        padding: EdgeInsets.only(
          left: 10.0,
          right: 10.0,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        color: Colors.white,
        onPressed: () {
          // ????????????????????????????????????????????????
          if (widget.player.value.fullScreen) {
            player.exitFullScreen();
          } else {
            if (widget.pageContent == null) return null;
            player.stop();
            Navigator.pop(widget.pageContent!);
          }
        },
      ),
    );
  }

  // ???????????? - ????????????
  Widget _buildPlayerListDrawer() {
    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await _animationController!.reverse();
                setState(() {
                  _drawerState = false;
                });
              },
            ),
          ),
          Container(
            child: SlideTransition(
              position: _animation!,
              child: Container(
                height: window.physicalSize.height,
                width: 320,
                child: _buildPlayDrawer(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // build ??????
  Widget _buildPlayDrawer() {
    return Scaffold(
      backgroundColor: Color.fromRGBO(0, 0, 0, 0.4),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.5),
        automaticallyImplyLeading: false,
        elevation: 0.1,
        title: TabBar(
          labelColor: Colors.white,
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          unselectedLabelColor: Colors.white,
          unselectedLabelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          indicator: BoxDecoration(
            color: Colors.purple[700],
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          tabs:
              _videoSourceTabs.video!.map((e) => Tab(text: e!.name!)).toList(),
          isScrollable: true,
          controller: _tabController,
        ),
      ),
      body: Container(
        color: Color.fromRGBO(0, 0, 0, 0.5),
        child: TabBarView(
          controller: _tabController,
          children: _createTabConList(),
        ),
      ),
    );
  }

  // ?????? tabCon
  List<Widget> _createTabConList() {
    List<Widget> list = [];
    _videoSourceTabs.video!.asMap().keys.forEach((int tabIdx) {
      List<Widget> playListBtns = _videoSourceTabs.video![tabIdx]!.list!
          .asMap()
          .keys
          .map((int activeIdx) {
        return Padding(
          padding: EdgeInsets.only(left: 5, right: 5),
          child: ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
              backgroundColor: MaterialStateProperty.all(
                  tabIdx == widget.curTabIdx && activeIdx == widget.curActiveIdx
                      ? Colors.red
                      : Colors.blue),
            ),
            onPressed: () {
              int newTabIdx = tabIdx;
              int newActiveIdx = activeIdx;
              // ???????????????
              changeCurPlayVideo(newTabIdx, newActiveIdx);
            },
            child: Text(
              _videoSourceTabs.video![tabIdx]!.list![activeIdx]!.name!,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList();
      //
      list.add(
        SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(left: 5, right: 5),
            child: Wrap(
              direction: Axis.horizontal,
              children: playListBtns,
            ),
          ),
        ),
      );
    });
    return list;
  }

  // ?????????????????????
  Widget _buildPublicFrameWidget({
    required Widget slot,
    Color? bgColor,
  }) {
    return Container(
      color: bgColor,
      child: Stack(
        children: [
          showConfig.topBar
              ? Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: Container(
                    height:
                        showConfig.stateAuto && !widget.player.value.fullScreen
                            ? barFillingHeight
                            : barHeight,
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      height: barHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          _buildTopBackBtn(),
                          Expanded(
                            child: Container(
                              child: Text(
                                widget.playerTitle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 0,
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                    top: showConfig.stateAuto && !widget.player.value.fullScreen
                        ? barGap
                        : 0),
                child: slot,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ??????slot
  Widget _buildErrorStateSlotWidget() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: showConfig.stateAuto && !widget.player.value.fullScreen
                ? barGap
                : 0,
          ),
          // ????????????
          Icon(
            Icons.error,
            size: 50,
            color: Colors.white,
          ),
          // ????????????
          Text(
            "???????????????????????????????????????",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          // ??????
          ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
              backgroundColor: MaterialStateProperty.all(Colors.white),
            ),
            onPressed: () {
              // ????????????
              changeCurPlayVideo(widget.curTabIdx, widget.curActiveIdx);
            },
            child: Text(
              "????????????",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ?????????slot
  Widget _buildLoadingStateSlotWidget() {
    return SizedBox(
      width: barHeight * 0.8,
      height: barHeight * 0.8,
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.white),
      ),
    );
  }

  // ?????????slot
  Widget _buildIdleStateSlotWidget() {
    return IconButton(
      iconSize: barHeight * 1.2,
      icon: Icon(Icons.play_arrow, color: Colors.white),
      padding: EdgeInsets.only(left: 10.0, right: 10.0),
      onPressed: () async {
        int newTabIdx = widget.curTabIdx;
        int newActiveIdx = widget.curActiveIdx;
        await changeCurPlayVideo(newTabIdx, newActiveIdx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = player.value.fullScreen
        ? Rect.fromLTWH(
            0,
            0,
            widget.viewSize.width,
            widget.viewSize.height,
          )
        : Rect.fromLTRB(
            max(0.0, widget.texturePos.left),
            max(0.0, widget.texturePos.top),
            min(widget.viewSize.width, widget.texturePos.right),
            min(widget.viewSize.height, widget.texturePos.bottom),
          );

    List<Widget> ws = [];

    if (_playerState == FijkState.error) {
      ws.add(
        _buildPublicFrameWidget(
          slot: _buildErrorStateSlotWidget(),
          bgColor: Colors.black,
        ),
      );
    } else if ((_playerState == FijkState.asyncPreparing ||
            _playerState == FijkState.initialized) &&
        !_isPlaying) {
      ws.add(
        _buildPublicFrameWidget(
          slot: _buildLoadingStateSlotWidget(),
          bgColor: Colors.black,
        ),
      );
    } else if (_playerState == FijkState.idle && !_isPlaying) {
      ws.add(
        _buildPublicFrameWidget(
          slot: _buildIdleStateSlotWidget(),
          bgColor: Colors.black,
        ),
      );
    } else {
      if (_lockStuff == true &&
          showConfig.lockBtn &&
          widget.player.value.fullScreen) {
        ws.add(
          _buidLockStateDetctor(),
        );
      } else if (_drawerState == true && widget.player.value.fullScreen) {
        ws.add(
          _buildPlayerListDrawer(),
        );
      } else {
        ws.add(
          _buildGestureDetector(
            curActiveIdx: widget.curActiveIdx,
            curTabIdx: widget.curTabIdx,
            onChangeVideo: widget.onChangeVideo,
            player: widget.player,
            texturePos: widget.texturePos,
            showConfig: widget.showConfig,
            pageContent: widget.pageContent,
            playerTitle: widget.playerTitle,
            viewSize: widget.viewSize,
            videoFormat: widget.videoFormat,
            changeDrawerState: changeDrawerState,
            changeLockState: changeLockState,
          ),
        );
      }
    }

    return WillPopScope(
      child: Positioned.fromRect(
        rect: rect,
        child: Stack(
          children: ws,
        ),
      ),
      onWillPop: () async {
        if (!widget.player.value.fullScreen) widget.player.stop();
        return true;
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _buildGestureDetector extends StatefulWidget {
  final FijkPlayer player;
  final Size viewSize;
  final Rect texturePos;
  final BuildContext? pageContent;
  final String playerTitle;
  final Function? onChangeVideo;
  final int curTabIdx;
  final int curActiveIdx;
  final Function changeDrawerState;
  final Function changeLockState;
  final ShowConfigAbs showConfig;
  final VideoSourceFormat? videoFormat;
  _buildGestureDetector({
    Key? key,
    required this.player,
    required this.viewSize,
    required this.texturePos,
    this.pageContent,
    this.playerTitle = "",
    required this.showConfig,
    this.onChangeVideo,
    required this.curTabIdx,
    required this.curActiveIdx,
    required this.videoFormat,
    required this.changeDrawerState,
    required this.changeLockState,
  }) : super(key: key);

  @override
  _buildGestureDetectorState createState() => _buildGestureDetectorState();
}

class _buildGestureDetectorState extends State<_buildGestureDetector> {
  FijkPlayer get player => widget.player;
  ShowConfigAbs get showConfig => widget.showConfig;
  VideoSourceFormat get _videoSourceTabs => widget.videoFormat!;

  Duration _duration = Duration();
  Duration _currentPos = Duration();
  Duration _bufferPos = Duration();

  // ????????????
  Duration _dargPos = Duration();

  bool _isTouch = false;

  bool _playing = false;
  bool _prepared = false;
  String? _exception;

  double? updatePrevDx;
  double? updatePrevDy;
  int? updatePosX;

  bool? isDargVerLeft;

  double? updateDargVarVal;

  bool varTouchInitSuc = false;

  bool _buffering = false;

  double _seekPos = -1.0;

  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;
  StreamSubscription? _bufferingSubs;

  Timer? _hideTimer;
  bool _hideStuff = true;

  bool _hideSpeedStu = true;
  double _speed = speed;

  bool _isHorizontalMove = false;

  Map<String, double> speedList = {
    "2.0": 2.0,
    "1.8": 1.8,
    "1.5": 1.5,
    "1.2": 1.2,
    "1.0": 1.0,
  };

  // ?????????????????????
  _buildGestureDetectorState();

  void initEvent() {
    // ?????????????????????????????????????????????????????????
    setState(() {
      _speed = speed;
      // ??????????????????????????????????????????????????????
      _hideStuff = !_playing ? false : true;
    });
    // ????????????
    _startHideTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _hideTimer?.cancel();

    player.removeListener(_playerValueChanged);
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    _bufferingSubs?.cancel();
  }

  @override
  void initState() {
    super.initState();

    initEvent();

    _duration = player.value.duration;
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;
    _prepared = player.state.index >= FijkState.prepared.index;
    _playing = player.state == FijkState.started;
    _exception = player.value.exception.message;
    _buffering = player.isBuffering;

    player.addListener(_playerValueChanged);

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      setState(() {
        _currentPos = v;
        // ??????????????????fijkplay reset?????????????????????bug???
        _playing = true;
        _prepared = true;
      });
    });

    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      setState(() {
        _bufferPos = v;
      });
    });

    _bufferingSubs = player.onBufferStateUpdate.listen((v) {
      setState(() {
        _buffering = v;
      });
    });
  }

  void _playerValueChanged() async {
    FijkValue value = player.value;
    if (value.duration != _duration) {
      setState(() {
        _duration = value.duration;
      });
    }
    print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    print('++++++++ ?????????????????? => ${value.state == FijkState.started} ++++++++');
    print('+++++++++++++++++++ ??????????????? => ${value.state} ++++++++++++++++++++');
    print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    // ?????????
    bool playing = value.state == FijkState.started;
    bool prepared = value.prepared;
    String? exception = value.exception.message;
    // ????????????????????????
    if (playing != _playing ||
        prepared != _prepared ||
        exception != _exception) {
      setState(() {
        _playing = playing;
        _prepared = prepared;
        _exception = exception;
      });
    }
    // ????????????
    bool playend = (value.state == FijkState.completed);
    bool isOverFlow = widget.curActiveIdx + 1 >=
        _videoSourceTabs.video![widget.curTabIdx]!.list!.length;
    // ???????????? && tablen???????????? && curActive????????????
    if (playend && !isOverFlow && showConfig.autoNext) {
      int newTabIdx = widget.curTabIdx;
      int newActiveIdx = widget.curActiveIdx + 1;
      widget.onChangeVideo!(newTabIdx, newActiveIdx);
      // ???????????????
      changeCurPlayVideo(newTabIdx, newActiveIdx);
    }
  }

  _onHorizontalDragStart(detills) {
    setState(() {
      updatePrevDx = detills.globalPosition.dx;
      updatePosX = _currentPos.inMilliseconds;
    });
  }

  _onHorizontalDragUpdate(detills) {
    double curDragDx = detills.globalPosition.dx;
    // ?????????????????????????????????
    int cdx = curDragDx.toInt();
    int pdx = updatePrevDx!.toInt();
    bool isBefore = cdx > pdx;

    // ???????????????????????????
    int newInterval = pdx - cdx;
    double playerW = MediaQuery.of(context).size.width;
    int curIntervalAbs = newInterval.abs();
    double movePropCheck = (curIntervalAbs / playerW) * 100;

    // ????????????????????????
    double durProgCheck = _duration.inMilliseconds.toDouble() / 100;
    int checkTransfrom = (movePropCheck * durProgCheck).toInt();
    int dragRange =
        isBefore ? updatePosX! + checkTransfrom : updatePosX! - checkTransfrom;

    // ???????????? ??????
    int lastSecond = _duration.inMilliseconds;
    if (dragRange >= _duration.inMilliseconds) {
      dragRange = lastSecond;
    }
    // ???????????? ??????
    if (dragRange <= 0) {
      dragRange = 0;
    }
    //
    this.setState(() {
      _isHorizontalMove = true;
      _hideStuff = false;
      _isTouch = true;
      // ????????????????????????????????????
      updatePrevDx = curDragDx;
      // ????????????
      updatePosX = dragRange.toInt();
      _dargPos = Duration(milliseconds: updatePosX!.toInt());
    });
  }

  _onHorizontalDragEnd(detills) {
    player.seekTo(_dargPos.inMilliseconds);
    this.setState(() {
      _isHorizontalMove = false;
      _isTouch = false;
      _hideStuff = true;
      _currentPos = _dargPos;
    });
  }

  _onVerticalDragStart(detills) async {
    double clientW = widget.viewSize.width;
    double curTouchPosX = detills.globalPosition.dx;

    setState(() {
      // ????????????
      updatePrevDy = detills.globalPosition.dy;
      // ????????????
      isDargVerLeft = (curTouchPosX > (clientW / 2)) ? false : true;
    });
    // ?????? ?????? ?????? ??? ?????? ?????? ??????
    if (!isDargVerLeft!) {
      // ??????
      await FijkVolume.getVol().then((double v) {
        varTouchInitSuc = true;
        setState(() {
          updateDargVarVal = v;
        });
      });
    } else {
      // ??????
      await FijkPlugin.screenBrightness().then((double v) {
        varTouchInitSuc = true;
        setState(() {
          updateDargVarVal = v;
        });
      });
    }
  }

  _onVerticalDragUpdate(detills) {
    if (!varTouchInitSuc) return null;
    double curDragDy = detills.globalPosition.dy;
    // ?????????????????????????????????
    int cdy = curDragDy.toInt();
    int pdy = updatePrevDy!.toInt();
    bool isBefore = cdy < pdy;
    // + -, ?????????, ??????????????????????????????> 3
    if (isBefore && pdy - cdy < 3 || !isBefore && cdy - pdy < 3) return null;
    // ??????
    double dragRange =
        isBefore ? updateDargVarVal! + 0.03 : updateDargVarVal! - 0.03;
    // ????????????
    if (dragRange > 1) {
      dragRange = 1.0;
    }
    if (dragRange < 0) {
      dragRange = 0.0;
    }
    setState(() {
      updatePrevDy = curDragDy;
      varTouchInitSuc = true;
      updateDargVarVal = dragRange;
      // ??????
      if (!isDargVerLeft!) {
        FijkVolume.setVol(dragRange);
      } else {
        FijkPlugin.setScreenBrightness(dragRange);
      }
    });
  }

  _onVerticalDragEnd(detills) {
    setState(() {
      varTouchInitSuc = false;
    });
  }

  // ???????????????
  Future<void> changeCurPlayVideo(int tabIdx, int activeIdx) async {
    // await player.seekTo(0);
    await player.stop();
    setState(() {
      _buffering = false;
    });
    player.reset().then((_) {
      _speed = speed = 1.0;
      String curTabActiveUrl =
          _videoSourceTabs.video![tabIdx]!.list![activeIdx]!.url!;
      player.setDataSource(
        curTabActiveUrl,
        autoPlay: true,
      );
      // ??????
      widget.onChangeVideo!(tabIdx, activeIdx);
    });
  }

  void _playOrPause() {
    if (_playing == true) {
      player.pause();
    } else {
      player.start();
    }
  }

  void _cancelAndRestartTimer() {
    if (_hideStuff == true) {
      _startHideTimer();
    }

    setState(() {
      _hideStuff = !_hideStuff;
      if (_hideStuff == true) {
        _hideSpeedStu = true;
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _hideStuff = true;
        _hideSpeedStu = true;
      });
    });
  }

  // ??????????????? - ????????????
  Widget _buildPlayStateBtn(IconData iconData, Function cb) {
    return Ink(
      child: InkWell(
        onTap: () => cb(),
        child: Container(
          height: 30,
          child: Padding(
            padding: EdgeInsets.only(left: 5, right: 5),
            child: Icon(
              iconData,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ?????????ui ??????
  Widget _buildBottomBar(BuildContext context) {
    // ??????????????????
    double duration = _duration.inMilliseconds.toDouble();
    double currentValue = _seekPos > 0
        ? _seekPos
        : (_isHorizontalMove
            ? _dargPos.inMilliseconds.toDouble()
            : _currentPos.inMilliseconds.toDouble());
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);

    // ????????????????????????
    double curConWidth = MediaQuery.of(context).size.width;
    double curTimePro = (currentValue / duration) * 100;
    double curBottomProW = (curConWidth / 100) * curTimePro;

    return Container(
      height: barHeight,
      child: Stack(
        children: [
          // ??????UI?????????
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _hideStuff ? 0.0 : 0.8,
              duration: Duration(milliseconds: 400),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0),
                      Color.fromRGBO(0, 0, 0, 0.4),
                    ],
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 7),
                    // ?????? - ??????/??????
                    _buildPlayStateBtn(
                      _playing ? Icons.pause : Icons.play_arrow,
                      _playOrPause,
                    ),
                    // ?????????
                    showConfig.nextBtn
                        ? _buildPlayStateBtn(
                            Icons.skip_next,
                            () {
                              bool isOverFlow = widget.curActiveIdx + 1 >=
                                  _videoSourceTabs
                                      .video![widget.curTabIdx]!.list!.length;
                              // ????????????????????????
                              if (!isOverFlow) {
                                int newTabIdx = widget.curTabIdx;
                                int newActiveIdx = widget.curActiveIdx + 1;
                                // ???????????????
                                changeCurPlayVideo(newTabIdx, newActiveIdx);
                              }
                            },
                          )
                        : Container(),
                    // ???????????????
                    Padding(
                      padding: EdgeInsets.only(right: 5.0, left: 5),
                      child: Text(
                        '${_duration2String(_currentPos)}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // ???????????? if ?????????????????? ????????????ui??? else fijkSlider widget
                    _duration.inMilliseconds == 0
                        ? Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 5, left: 5),
                              child: NewFijkSlider(
                                colors: NewFijkSliderColors(
                                  cursorColor: Colors.blue,
                                  playedColor: Colors.blue,
                                ),
                                onChangeEnd: (double value) {},
                                value: 0,
                                onChanged: (double value) {},
                              ),
                            ),
                          )
                        : Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 5, left: 5),
                              child: NewFijkSlider(
                                colors: NewFijkSliderColors(
                                  cursorColor: Colors.blue,
                                  playedColor: Colors.blue,
                                ),
                                value: currentValue,
                                cacheValue:
                                    _bufferPos.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: duration,
                                onChanged: (v) {
                                  _startHideTimer();
                                  setState(() {
                                    _seekPos = v;
                                  });
                                },
                                onChangeEnd: (v) {
                                  setState(() {
                                    player.seekTo(v.toInt());
                                    print("seek to $v");
                                    _currentPos = Duration(
                                        milliseconds: _seekPos.toInt());
                                    _seekPos = -1;
                                  });
                                },
                              ),
                            ),
                          ),

                    // ???????????????
                    _duration.inMilliseconds == 0
                        ? Container(
                            child: const Text(
                              "00:00",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.only(right: 5.0, left: 5),
                            child: Text(
                              '${_duration2String(_duration)}',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    // ????????????
                    widget.player.value.fullScreen && showConfig.drawerBtn
                        ? Ink(
                            padding: EdgeInsets.all(5),
                            child: InkWell(
                              onTap: () {
                                // ????????????????????????
                                widget.changeDrawerState(true);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: 40,
                                height: 30,
                                child: Text(
                                  "??????",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    // ????????????
                    widget.player.value.fullScreen && showConfig.speedBtn
                        ? Ink(
                            padding: EdgeInsets.all(5),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _hideSpeedStu = !_hideSpeedStu;
                                });
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: 40,
                                height: 30,
                                child: Text(
                                  _speed.toString() + " X",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    // ?????? - ??????/????????????
                    _buildPlayStateBtn(
                      widget.player.value.fullScreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      () {
                        if (widget.player.value.fullScreen) {
                          player.exitFullScreen();
                        } else {
                          player.enterFullScreen();
                          // ??????????????????
                          widget.changeDrawerState(false);
                        }
                      },
                    ),
                    SizedBox(width: 7),
                    //
                  ],
                ),
              ),
            ),
          ),
          // ??????????????????ui???????????????
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: showConfig.bottomPro &&
                    _hideStuff &&
                    _duration.inMilliseconds != 0
                ? Container(
                    alignment: Alignment.bottomLeft,
                    height: 4,
                    color: Colors.white70,
                    child: Container(
                      color: Colors.blue,
                      width: curBottomProW is double ? curBottomProW : 0,
                      height: 4,
                    ),
                  )
                : Container(),
          )
        ],
      ),
    );
  }

  // ????????????
  Widget _buildTopBackBtn() {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      padding: EdgeInsets.only(
        left: 10.0,
        right: 10.0,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      color: Colors.white,
      onPressed: () {
        // ????????????????????????????????????????????????
        if (widget.player.value.fullScreen) {
          player.exitFullScreen();
        } else {
          if (widget.pageContent == null) return null;
          player.stop();
          Navigator.pop(widget.pageContent!);
        }
      },
    );
  }

  // ??????????????? ?????? + ??????
  Widget _buildTopBar() {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 0.8,
      duration: Duration(milliseconds: 400),
      child: Container(
        height: showConfig.stateAuto && !widget.player.value.fullScreen
            ? barFillingHeight
            : barHeight,
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromRGBO(0, 0, 0, 0.5),
              Color.fromRGBO(0, 0, 0, 0),
            ],
          ),
        ),
        child: Container(
          height: barHeight,
          child: Row(
            children: <Widget>[
              _buildTopBackBtn(),
              Expanded(
                child: Container(
                  child: Text(
                    widget.playerTitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ??????????????????
  Widget _buildCenterPlayBtn() {
    return Container(
      color: Colors.transparent,
      height: double.infinity,
      width: double.infinity,
      child: Center(
        child: (_prepared && !_buffering)
            ? AnimatedOpacity(
                opacity: _hideStuff ? 0.0 : 0.7,
                duration: Duration(milliseconds: 400),
                child: IconButton(
                  iconSize: barHeight * 1.2,
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white),
                  padding: EdgeInsets.only(left: 10.0, right: 10.0),
                  onPressed: _playOrPause,
                ),
              )
            : SizedBox(
                width: barHeight * 0.8,
                height: barHeight * 0.8,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
      ),
    );
  }

  // build ????????????????????????
  Widget _buildDargProgressTime() {
    return _isTouch
        ? Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
              color: Color.fromRGBO(0, 0, 0, 0.8),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                '${_duration2String(_dargPos)} / ${_duration2String(_duration)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          )
        : Container();
  }

  // build ???????????????????????????
  Widget _buildDargVolumeAndBrightness() {
    // ?????????
    if (!varTouchInitSuc) return Container();

    IconData iconData;
    // ???????????????????????????????????????
    if (updateDargVarVal! <= 0) {
      iconData = !isDargVerLeft! ? Icons.volume_mute : Icons.brightness_low;
    } else if (updateDargVarVal! < 0.5) {
      iconData = !isDargVerLeft! ? Icons.volume_down : Icons.brightness_medium;
    } else {
      iconData = !isDargVerLeft! ? Icons.volume_up : Icons.brightness_high;
    }
    // ??????????????? || ??????
    return Card(
      color: Color.fromRGBO(0, 0, 0, 0.8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              iconData,
              color: Colors.white,
            ),
            Container(
              width: 100,
              height: 3,
              margin: EdgeInsets.only(left: 8),
              child: LinearProgressIndicator(
                value: updateDargVarVal,
                backgroundColor: Colors.white54,
                valueColor: AlwaysStoppedAnimation(Colors.lightBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // build ????????????
  List<Widget> _buildSpeedListWidget() {
    List<Widget> columnChild = [];
    speedList.forEach((String mapKey, double speedVals) {
      columnChild.add(
        Ink(
          child: InkWell(
            onTap: () {
              if (_speed == speedVals) return null;
              setState(() {
                _speed = speed = speedVals;
                _hideSpeedStu = true;
                player.setSpeed(speedVals);
              });
            },
            child: Container(
              alignment: Alignment.center,
              width: 50,
              height: 30,
              child: Text(
                mapKey + " X",
                style: TextStyle(
                  color: _speed == speedVals ? Colors.blue : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
      columnChild.add(
        Padding(
          padding: EdgeInsets.only(top: 5, bottom: 5),
          child: Container(
            width: 50,
            height: 1,
            color: Colors.white54,
          ),
        ),
      );
    });
    columnChild.removeAt(columnChild.length - 1);
    return columnChild;
  }

  // ?????????????????? ui
  Widget _buildGestureDetector() {
    return GestureDetector(
      onTap: _cancelAndRestartTimer,
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: Column(
          children: <Widget>[
            // ????????????????????????
            showConfig.topBar
                ? _buildTopBar()
                : Container(
                    height:
                        showConfig.stateAuto && !widget.player.value.fullScreen
                            ? barFillingHeight
                            : barHeight,
                  ),
            // ????????????
            Expanded(
              child: Stack(
                children: <Widget>[
                  // ????????????
                  Positioned(
                    top: widget.player.value.fullScreen ? 20 : 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ????????????????????????????????????
                        _buildDargProgressTime(),
                        // ??????????????????????????????
                        _buildDargVolumeAndBrightness()
                      ],
                    ),
                  ),
                  // ????????????
                  Align(
                    alignment: Alignment.center,
                    child: _buildCenterPlayBtn(),
                  ),
                  // ????????????
                  Positioned(
                    right: 35,
                    bottom: 0,
                    child: !_hideSpeedStu
                        ? Container(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                children: _buildSpeedListWidget(),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          )
                        : Container(),
                  ),
                  // ?????????
                  showConfig.lockBtn && widget.player.value.fullScreen
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedOpacity(
                            opacity: _hideStuff ? 0.0 : 0.7,
                            duration: Duration(milliseconds: 400),
                            child: Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: IconButton(
                                iconSize: 30,
                                onPressed: () {
                                  // ?????? ui????????????
                                  widget.changeLockState(true);
                                },
                                icon: Icon(Icons.lock_outline),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
            // ????????????????????????
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildGestureDetector();
  }
}
