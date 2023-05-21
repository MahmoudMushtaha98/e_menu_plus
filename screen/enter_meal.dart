import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:newemenu/screen/login.dart';
import 'package:newemenu/widget/textbutton.dart';
import '../model/meal_controler_model.dart';

class EnterTheMeals extends StatefulWidget {
  final List categories;
  final List numberOfMeals;
  final String id;

  const EnterTheMeals({Key? key,
    required this.categories,
    required this.numberOfMeals, required this.id,})
      : super(key: key);

  @override
  State<EnterTheMeals> createState() => _EnterTheMealsState();
}

class _EnterTheMealsState extends State<EnterTheMeals> {
  Map<int, List<MealControlerModel>> map = {};
  final _firestore=FirebaseFirestore.instance;

  @override
  void initState() {
    _fillMealsControllers();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _saving=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        body: ModalProgressHUD(
          inAsyncCall: _saving,
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  Column(
                    children: List.generate(widget.categories.length, (counter) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 0, 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: double.infinity,
                            ),
                            Text(
                              '${widget.categories[counter]}:',
                              style: const TextStyle(color: Colors.grey, fontSize: 20),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListView.builder(
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              buildSizedBoxOfTextfield(
                                                  context,
                                                  index,
                                                  0.6,
                                                  'Meal name',
                                                  0,
                                                  map[counter]![index].mealName),
                                              SizedBox(
                                                width: MediaQuery
                                                    .of(context)
                                                    .size
                                                    .width *
                                                    0.05,
                                              ),
                                              buildSizedBoxOfTextfield(
                                                  context,
                                                  index,
                                                  0.2,
                                                  'Price',
                                                  1,
                                                  map[counter]![index].price),
                                            ],
                                          ),
                                          buildSizedBoxOfTextfield(
                                              context,
                                              index,
                                              0.85,
                                              'Meal components',
                                              0,
                                              map[counter]![index].components),
                                          SizedBox(
                                            height:
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .height *
                                                0.05,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  shrinkWrap: true,
                                  itemCount: map[counter]!.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero),
                            )
                          ],
                        ),
                      );
                    }),
                  ),
                  TextButtonWidget(text: 'Submit', callback: () async{
                    setState(() {
                      _saving=true;
                    });
                    await deleteMeals();
                    if(mounted) {
                      await selectMeals();
                    }
                    map.forEach((key, value) {
                      List<MealControlerModel> meals=value;
                    });
                    if(mounted) {
                      setState(() {
                        _saving=false;
                      });
                      Navigator.pushReplacement(context, MaterialPageRoute(
                          builder: (context) => LoginPage()));
                    }
                    },),
                  SizedBox(
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.05,
                  )
                ],
              ),
            ),
          ),
        ));
  }

  Future<void> deleteMeals() async {
    final del=await _firestore.collection('All').where('emailID',isEqualTo: widget.id).get();
    if(del.docs.isNotEmpty){
      for(var dele in del.docs){
        dele.reference.delete();
      }
    }
  }

  Future<void> selectMeals() async {
    List<String> mealNames = [];
    List<double> mealPrice = [];
    List<String> mealComponents = [];

    List mealsLists = map.values.toList();
    for (var meals in mealsLists) {
      for (var meal in meals) {
        mealNames.add(meal.mealName.text);
        mealPrice.add((double.parse(meal.price.text)));
        mealComponents.add(meal.components.text);
      }
    }



    int j=0;
    for(int counter=0;counter<widget.categories.length;counter++){
      String cat=widget.categories[counter];
      for(int i=0;i<widget.numberOfMeals[counter];i++){
        try{
          await _firestore.collection('All').add({
            'counter': i,
            'emailID':widget.id,
            'mealComponents':mealComponents[j],
            'mealName':mealNames[j],
            'price':mealPrice[j],
            'type':cat
          });
        }catch(e){
          if (kDebugMode) {
            print(e);
          }
        }
        j++;
      }
    }
  }

  SizedBox buildSizedBoxOfTextfield(BuildContext context,
      int index,
      double ourWidth,
      String label,
      int numb,
      TextEditingController controller,) {
    return SizedBox(
      width: MediaQuery
          .of(context)
          .size
          .width * ourWidth,
      height: 70,
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          label: Text(label,style: const TextStyle(color: Colors.grey,fontWeight: FontWeight.bold),),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromRGBO(212, 175, 55, 1),
              ),
              borderRadius: BorderRadius.all(Radius.circular(15))
          ),

        ),
        inputFormatters: numb == 1
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
            : null,
        keyboardType: numb == 1 ? TextInputType.number : null,
        controller: controller,
      ),
    );
  }





  void _fillMealsControllers() {
    List.generate(widget.categories.length, (index) {
      List<MealControlerModel> meals = [];
      for (int c=0;c<widget.numberOfMeals[index];c++) {
        meals.add(MealControlerModel());
      }
      map.putIfAbsent(index, () => meals);
    });
  }
}

