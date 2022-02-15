---
title: " Applications Page Reference"
linkTitle: "Applications Page Reference"
weight: 30
---

The __Applications__ tab displays all of your applications. For a detailed explanation of the view, refer to the table below:



| Column        |      Description                               |  Possible Values                                                    |
|:--------------|:-----------------------------------------------|:--------------------------------------------------------------------|
| __App Name__  | The name of the app                            | `String` (can contain special characters)                           |
| __Kind__      | Indicates the kind of application.                              | __Replica__ <br />  __StatefulSet__ <br /> __Deployment__           |
| __Pods__      | The number of pods for your application        | `Integer`                                                           |
| __Pod Status__| Indicates the number of pods that are ready/syncing or with unknown/failed status| __Ready__ <br /> __Syncing__ <br /> __Unknown__ <br /> __Failed__   |
| __PV Amount__ | Indicates the amount of PVs taken up by the app| `Integer`                                                           |
| __PVs Size__  | Indicates the size of all Persistent volumes as a percentage of all available storage on all pods  |      Available GB on the pods|
| __PVs Status__| Indicates the number of PVs that are ready/syncing or with unknown/failed status| __Ready__ <br /> __Syncing__ <br /> __Unknown__ <br /> __Failed__   |


## Detailed View of the Application

To view more details of your application, click __View Details__ and you will be given an overview of the status of the app. 
