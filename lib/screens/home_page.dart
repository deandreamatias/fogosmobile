import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:fogosmobile/actions/fires_actions.dart';
import 'package:fogosmobile/actions/modis_actions.dart';
import 'package:fogosmobile/actions/preferences_actions.dart';
import 'package:fogosmobile/actions/viirs_actions.dart';
import 'package:fogosmobile/constants/variables.dart';
import 'package:fogosmobile/localization/fogos_localizations.dart';
import 'package:fogosmobile/middleware/preferences_middleware.dart';
import 'package:fogosmobile/models/app_state.dart';
import 'package:fogosmobile/models/fire.dart';
import 'package:fogosmobile/models/lightning.dart';
import 'package:fogosmobile/models/modis.dart';
import 'package:fogosmobile/models/viirs.dart';
import 'package:fogosmobile/screens/components/fire_details.dart';
import 'package:fogosmobile/screens/components/mapbox_copyright.dart';
import 'package:fogosmobile/screens/marker_fire.dart';
import 'package:fogosmobile/screens/marker_lightning.dart';
import 'package:fogosmobile/screens/marker_modis.dart';
import 'package:fogosmobile/screens/marker_viirs.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:redux/redux.dart';

import '../main.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LatLng _center = new LatLng(39.806251, -8.088591);
  final List<String> _stylesStrings = [
    MAPBOX_TEMPLATE_STYLE,
    MAPBOX_URL_SATTELITE_TEMPLATE
  ];

  var currentMapboxTemplate = 0;

  MapboxMapController _mapController;

  Map<String, FireMarker> _fireMarkers = {};
  Map<String, ViirsMarker> _viirsMarkers = {};
  Map<String, ModiisMarker> _modisMarkers = {};
  Map<String, LightningMarker> _lightningMarkers = {};

  List<FireMarkerState> _fireMarkerStates = [];
  List<ViirsMarkerState> _viirsMarkerStates = [];
  List<ModiisMarkerState> _modisMarkerStates = [];
  List<LightningMarkerState> _lightningMarkerStates = [];

  void _clearMarkers() {
    _fireMarkers = {};
    _viirsMarkers = {};
    _modisMarkers = {};
    _lightningMarkers = {};

    _fireMarkerStates = [];
    _viirsMarkerStates = [];
    _modisMarkerStates = [];
    _lightningMarkerStates = [];
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    controller.addListener(() {
      if (controller.isCameraMoving) {
        _updateMarkerPosition();
      }
    });
  }

  void _addFireMarkerStates(FireMarkerState markerState) {
    _fireMarkerStates.add(markerState);
  }

  void _addViirsMarkerStates(ViirsMarkerState markerState) {
    _viirsMarkerStates.add(markerState);
  }

  void _addModisMarkerStates(ModiisMarkerState markerState) {
    _modisMarkerStates.add(markerState);
  }

  void _addLightningMarkerStates(LightningMarkerState markerState) {
    _lightningMarkerStates.add(markerState);
  }

  void _updateMarkerPosition() {
    // Fire
    final fireCoordinates = <LatLng>[];
    for (final markerState in _fireMarkerStates) {
      fireCoordinates.add(markerState.getCoordinate());
    }
    _mapController.toScreenLocationBatch(fireCoordinates).then((points) {
      _fireMarkerStates.asMap().forEach((i, value) {
        _fireMarkerStates[i].updatePosition(points[i]);
      });
    });

    // Viirs
    final viirsCoordinates = <LatLng>[];
    for (final markerState in _viirsMarkerStates) {
      viirsCoordinates.add(markerState.getCoordinate());
    }
    _mapController.toScreenLocationBatch(viirsCoordinates).then((points) {
      _viirsMarkerStates.asMap().forEach((i, value) {
        _viirsMarkerStates[i].updatePosition(points[i]);
      });
    });

    // Modis
    final modisCoordinates = <LatLng>[];
    for (final markerState in _modisMarkerStates) {
      modisCoordinates.add(markerState.getCoordinate());
    }
    _mapController.toScreenLocationBatch(modisCoordinates).then((points) {
      _modisMarkerStates.asMap().forEach((i, value) {
        _modisMarkerStates[i].updatePosition(points[i]);
      });
    });

    // Lightning
    final lightningCoordinates = <LatLng>[];
    for (final markerState in _lightningMarkerStates) {
      lightningCoordinates.add(markerState.getCoordinate());
    }
    _mapController.toScreenLocationBatch(lightningCoordinates).then((points) {
      _lightningMarkerStates.asMap().forEach((i, value) {
        _lightningMarkerStates[i].updatePosition(points[i]);
      });
    });
  }

  void _addFireMarker(Fire fire, LatLng coordinate, Point<double> point) {
    _fireMarkers.putIfAbsent(
      fire.id,
      () => FireMarker(
        fire.id,
        fire,
        coordinate,
        point,
        _addFireMarkerStates,
        () {
          _openModalSheet(context);
        },
      ),
    );
  }

  void _addModisMarker(Modis modis, LatLng coordinate, Point<double> point) {
    final modisId = modis.hashCode.toString();
    _modisMarkers.putIfAbsent(
        modisId,
        () => ModiisMarker(
              modisId,
              coordinate,
              point,
              _addModisMarkerStates,
              () {
                _openModisModal(context, modis);
              },
            ));
  }

  void _addViirsMarker(Viirs viirs, LatLng latLng, Point<double> point) {
    final virsId = viirs.hashCode.toString();
    _viirsMarkers.putIfAbsent(
      virsId,
      () => ViirsMarker(
        virsId,
        latLng,
        point,
        _addViirsMarkerStates,
        () {
          _openViirsModal(context, viirs);
        },
      ),
    );
  }

  void _addLightningMarker(
      Lightning lightning, LatLng latLng, Point<double> point) {
    _lightningMarkers.putIfAbsent(
      lightning.timestamp,
      () => LightningMarker(
        lightning.timestamp,
        latLng,
        point,
        _addLightningMarkerStates,
        () {
          // Add action
        },
      ),
    );
  }

  _openModalSheet(context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => FireDetails(),
    );
  }

  _openModisModal(BuildContext context, Modis modis) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => ModisModal(modis: modis),
    );
  }

  _openViirsModal(BuildContext context, Viirs viirs) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => ViirsModal(viirs: viirs),
    );
  }

  Widget _getSatelliteButton(state, context) {
    List<Widget> widgets = [
      IconButton(
        icon: Icon(Icons.satellite),
        onPressed: () {
          final store = StoreProvider.of<AppState>(context);
          store.dispatch(
            SetPreferenceAction(preferenceSatellite,
                state.preferences[preferenceSatellite] == 1 ? 0 : 1),
          );

          setState(() {});
        },
      ),
    ];

    if (state.preferences[preferenceSatellite] == 1) {
      widgets.add(Positioned(
        bottom: 5,
        right: 5,
        child: Icon(
          Icons.check_circle,
          size: 18,
          color: Colors.green,
        ),
      ));
    }

    return Stack(
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
        String fireId = message["data"]["fireId"];
        if (fireId != null) {
          final store = StoreProvider.of<AppState>(context);
          store.dispatch(ClearFireAction());
          store.dispatch(LoadFireAction(fireId));
          _openModalSheet(context);
        }
      },
      onLaunch: (Map<String, dynamic> message) async {},
    );

    return StoreConnector<AppState, AppState>(
      converter: (Store<AppState> store) => store.state,
      builder: (BuildContext context, AppState state) {
        currentMapboxTemplate =
            state.preferences[preferenceSatellite] == 1 ? 1 : 0;

        Widget overlayWidget = Container();

        if (state.fires.length < 1) {
          if (state.errors != null && state.errors.contains('fires')) {
            overlayWidget = Center(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.black54,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        FogosLocalizations.of(context).textProblemLoadingData,
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        FogosLocalizations.of(context).textInternetConnection,
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }

        if (state.fires != null && _mapController != null) {
          for (final Fire fire in state.fires) {
            if (state.activeFilters.contains(fire.status) &&
                !_fireMarkers.containsKey(fire.id)) {
              double pinSize = fullPinSize * fire.scale;

              if (pinSize == 0) {
                pinSize = fullPinSize;
              }

              final latLng = LatLng(fire.lat, fire.lng);
              // TODO: Use toScreenLocationBatch for better performance
              _mapController.toScreenLocation(latLng).then((value) {
                var point = Point<double>(value.x as double, value.y as double);
                _addFireMarker(fire, latLng, point);
              });
            }
          }
        }

        if (state.modis != null &&
            (state.showModis ?? false) &&
            _mapController != null) {
          for (final Modis modis in state.modis) {
            if (modis.latitude == null || modis.longitude == null) {
              continue;
            }
            final latLng = LatLng(modis.latitude, modis.longitude);
            _mapController.toScreenLocation(latLng).then((value) {
              var point = Point<double>(value.x as double, value.y as double);
              _addModisMarker(modis, latLng, point);
            });
          }
        }

        if (state.viirs != null &&
            (state.showViirs ?? false) &&
            _mapController != null) {
          for (final Viirs viirs in state.viirs) {
            if (viirs.latitude == null || viirs.longitude == null) {
              continue;
            }

            final latLng = LatLng(viirs.latitude, viirs.longitude);
            _mapController.toScreenLocation(latLng).then((value) {
              var point = Point<double>(value.x as double, value.y as double);
              _addViirsMarker(viirs, latLng, point);
            });
          }
        }

        if ((state.lightnings?.isNotEmpty ?? false) && _mapController != null) {
          for (final Lightning lightning in state.lightnings) {
            final latLng = LatLng(
                lightning?.payload?.latitude, lightning?.payload?.longitude);
            _mapController.toScreenLocation(latLng).then((value) {
              var point = Point<double>(value.x as double, value.y as double);
              _addLightningMarker(lightning, latLng, point);
            });
          }
        }

        return ModalProgressHUD(
          opacity: 0.75,
          color: Colors.black,
          inAsyncCall: state.isLoading && state.fire == null,
          child: Stack(
            children: <Widget>[
              MapboxMap(
                accessToken: MAPBOX_ACCESS_TOKEN,
                trackCameraPosition: true,
                onMapCreated: _onMapCreated,
                styleString: _stylesStrings[currentMapboxTemplate],
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 7.0,
                ),
              ),
              IgnorePointer(
                ignoring: false,
                child: Stack(
                  children: _fireMarkers.values.toList(),
                ),
              ),
              IgnorePointer(
                ignoring: false,
                child: Stack(
                  children: _modisMarkers.values.toList(),
                ),
              ),
              IgnorePointer(
                ignoring: false,
                child: Stack(
                  children: _viirsMarkers.values.toList(),
                ),
              ),
              IgnorePointer(
                ignoring: false,
                child: Stack(
                  children: _lightningMarkers.values.toList(),
                ),
              ),
              MapboxCopyright(),
              Positioned(
                right: 0.0,
                top: 0.0,
                child: SafeArea(
                  child: Column(
                    children: [
                      _getBackground(
                        _getSatelliteButton(state, context),
                      ),
                      SizedBox(
                        height: 24,
                      ),
                      _getBackground(_getViirsButton(state, context)),
                      SizedBox(
                        height: 24,
                      ),
                      _getBackground(_getModisButton(state, context)),
                    ],
                  ),
                ),
              ),
              overlayWidget,
            ],
          ),
        );
      },
    );
  }

  Widget _getBackground(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14.0)),
        color: Colors.white54,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: child,
      ),
    );
  }

  Widget _getViirsButton(AppState state, context) {
    return InkWell(
      onTap: () =>
          StoreProvider.of<AppState>(context).dispatch(ShowViirsAction()),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Text('Viirs'),
          ),
          if (state.showViirs ?? false)
            Positioned(
              top: 5,
              right: 5,
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.green,
              ),
            )
        ],
      ),
    );
  }

  Widget _getModisButton(AppState state, context) {
    return InkWell(
      onTap: () =>
          StoreProvider.of<AppState>(context).dispatch(ShowModisAction()),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Text('Modis'),
          ),
          if (state.showModis ?? false)
            Positioned(
              top: 5,
              right: 5,
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.green,
              ),
            )
        ],
      ),
    );
  }
}

class ViirsModal extends StatelessWidget {
  final Viirs viirs;

  const ViirsModal({Key key, this.viirs}) : super(key: key);

  String getConfidence(BuildContext context, String confidence) {
    if (confidence == 'nominal') {
      return FogosLocalizations.of(context).textNominalConfidence;
    } else if (confidence == 'low') {
      return FogosLocalizations.of(context).textLowConfidence;
    } else if (confidence == 'high') {
      return FogosLocalizations.of(context).textHighConfidence;
    } else {
      return confidence;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: "${FogosLocalizations.of(context).textDate}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: getDate(viirs.acqDate),
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: "${FogosLocalizations.of(context).textBrightTi4}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: viirs.brightTi4,
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: "${FogosLocalizations.of(context).textBrightTi5}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: viirs.brightTi5,
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: "${FogosLocalizations.of(context).textFrp}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: viirs.frp, style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text:
                          "${FogosLocalizations.of(context).textConfidence}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: getConfidence(context, viirs.confidence),
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModisModal extends StatelessWidget {
  final Modis modis;

  const ModisModal({Key key, this.modis}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: "${FogosLocalizations.of(context).textDate}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: getDate(modis.acqDate),
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: "${FogosLocalizations.of(context).textBrightT31}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: modis.brightT31,
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text:
                          "${FogosLocalizations.of(context).textBrightness}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: modis.brightness,
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: "${FogosLocalizations.of(context).textFrp}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: modis.frp, style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text:
                          "${FogosLocalizations.of(context).textConfidence}: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(
                      text: "${modis.confidence}%",
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getDate(DateTime time) {
  String date = "${time.day}/${time.month}/${time.year}";
  String hours = DateFormat.Hm().format(time);
  return "$date - $hours";
}
