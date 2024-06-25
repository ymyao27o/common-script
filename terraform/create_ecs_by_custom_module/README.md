## terraform 脚本概述
1. alicloud 文档
    - alicloud 关于terraform的文档中，存在多种创建示例 `https://help.aliyun.com/document_detail/95829.html`
    - 关于创建ecs的示例，为单文件resource创建单个ecs，另一个为官方module创建多个ecs
2. 脚本
    - 该脚本为通过自定义模块创建单个ecs
    - 该脚本参考：https://www.bilibili.com/video/BV1T24y1Q78z
3. 具体参数
    - 输入键说明：https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/instance
    - 输入值选择：https://api.aliyun.com/api/Ecs/2014-05-26/DescribePrice
