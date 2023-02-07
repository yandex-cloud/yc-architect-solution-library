# Route switcher infra module
It is fork of original yc-route-switcher module:
https://github.com/yandex-cloud/yc-architect-solution-library/tree/main/yc-route-switcher

The module provides Active/Standby behaviour for two routers:
1. By default primary router is used for subnets
2. If primary router is not healthy, fails over to secondary router for subnets
3. If primary router is healthy, falls back to primary router for subnets

Please use this module only if you have a dedicated solution architect from Yandex.Cloud. Consult with him for any questions.




