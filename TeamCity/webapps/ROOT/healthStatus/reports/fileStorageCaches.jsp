<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
TeamCity has detected the usage of network file caches for the data directory. This may cause inconsistent directory state for the primary and secondary nodes.
<bs:help file="Disable-Network-Client-Caches-on-Data-Directory-Mounts"/>