import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:krishi_gyan/constants/colors.dart';
import 'package:krishi_gyan/provider/databaseProvider.dart';
import 'package:krishi_gyan/widgets/cards.dart';
// import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../models/product.dart';

enum WidgetMake { buy, sell }

class Mandi extends StatefulWidget {
  const Mandi({Key? key}) : super(key: key);
  @override
  State<Mandi> createState() => _MandiState();
}

class _MandiState extends State<Mandi> {
  WidgetMake b = WidgetMake.buy;

  Position? position;
  String? add1;
  String? add2;

  static const LatLng targetLocation =
      LatLng(28.621167966628416, 77.13521164582943);

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    //getAddress();
  }

  Future<void> getAddress(Position position) async {
    await placemarkFromCoordinates(position.latitude, position.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        add1 =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    // String datetime = DateTime.now().toString();
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Stack(alignment: Alignment.center, children: <Widget>[
              Container(
                height: size.height * 0.45,
                width: size.width,
                decoration: BoxDecoration(
                    color: darkGreen, //color
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.w),
                        bottomRight: Radius.circular(10.w))),

                // child: Align(
                //   alignment: Alignment.centerLeft,
                //   child: Row(
                //     children: <Widget>[
                //       Text(
                //         datetime,
                //         textAlign: TextAlign.left,
                //       ),
                //       SizedBox(
                //         width: size.width * 0.4,
                //       ),
                //       const Icon(Icons.person)
                //     ],
                //   ),
                // ),
              ),
              Positioned(
                top: 3.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.red),
                    height: 38.h,
                    width: 90.w,
                    alignment: Alignment.center,
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(28.621167966628416, 77.13521164582943),
                        zoom: 1,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 9.h,
                right: 20.w,
                child: Text(add1 ?? "",
                    style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.normal,
                        fontSize: 16.sp)),
              ),
            ]),
            SizedBox(
              height: 2.h,
            ),
            Container(
              margin: EdgeInsets.all(1.5.h),
              decoration: BoxDecoration(
                color: lightGreen, //color
                borderRadius: BorderRadius.all(
                  Radius.circular(10.w),
                ),
              ),
              height: size.height * 0.5,
              width: size.width,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 0.9.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              b = WidgetMake.buy;
                            });
                          },
                          child: Text("Buy",
                              style: TextStyle(
                                  fontSize: 23.sp,
                                  color: (b == WidgetMake.buy)
                                      ? Colors.black
                                      : Colors.black54)),
                        ),
                        SizedBox(
                          width: 30.w,
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              b = WidgetMake.sell;
                            });
                          },
                          child: Text(
                            "Sell",
                            style: TextStyle(
                                fontSize: 23.sp,
                                color: (b == WidgetMake.sell)
                                    ? Colors.black
                                    : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 1.h,
                    ),
                    Container(
                      child: getCustomContainer(),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getCustomContainer() {
    switch (b) {
      case WidgetMake.buy:
        return getbuycard();
      case WidgetMake.sell:
        return getSellForm(context);
      default:
        return getSellForm(context);
    }
  }

  Widget getSellForm(BuildContext context) {
    return const SellForm();
  }

  Widget getbuycard() {
    return StreamBuilder<List<Product>>(
        stream: context.read<DatabaseProvider>().getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          var products = snapshot.data!;
          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products found',
                style: TextStyle(fontSize: 16.sp),
              ),
            );
          }

          return Column(
              children: products
                  .map((product) => ProductCard(product: product))
                  .toList());
        });
  }
}

class SellForm extends StatefulWidget {
  const SellForm({Key? key}) : super(key: key);

  @override
  State<SellForm> createState() => _SellFormState();
}

class _SellFormState extends State<SellForm> {
  final _formKey = GlobalKey<FormState>();
  String _cropName = "";
  int _price = 0;
  int _quantity = 0;

  File? file;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: darkGreen),
            borderRadius: BorderRadius.circular(20.sp),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 20.sp),
            child: ListTile(
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Image(
                    image: AssetImage('assets/crop.png'),
                    color: darkGreen,
                  ),
                ],
              ),
              title: TextFormField(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Crop',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                onSaved: (newValue) => _cropName = newValue!,
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: darkGreen),
              borderRadius: BorderRadius.circular(20.sp)),
          child: Padding(
            padding: EdgeInsets.only(left: 20.sp),
            child: ListTile(
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  FaIcon(
                    FontAwesomeIcons.moneyBill1Wave,
                    color: darkGreen,
                  ),
                ],
              ),
              title: TextFormField(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Price',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (newValue) => _price = int.parse(newValue!),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: darkGreen),
              borderRadius: BorderRadius.circular(20.sp)),
          child: Padding(
            padding: EdgeInsets.only(left: 20.sp),
            child: ListTile(
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  FaIcon(
                    FontAwesomeIcons.weightScale,
                    color: darkGreen,
                  ),
                ],
              ),
              title: TextFormField(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Quantity',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (newValue) => _quantity = int.parse(newValue!),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          width: 30.w,
          child: ElevatedButton(
            onPressed: pickFile,
            child: Text(
              'Add image',
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 40,
              backgroundColor: darkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.sp),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          width: 30.w,
          child: ElevatedButton(
            onPressed: sellButtonPress,
            child: Text(
              'Save',
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 40,
              backgroundColor: darkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.sp),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void sellButtonPress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
        ),
      );
      return;
    }

    await context
        .read<DatabaseProvider>()
        .createProduct(_cropName, _price, _quantity, file!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product Sold!'),
      ),
    );
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
      });
    }
  }
}
