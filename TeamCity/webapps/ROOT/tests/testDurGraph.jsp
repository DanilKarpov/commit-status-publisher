<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@taglib prefix="stats" tagdir="/WEB-INF/tags/graph" %>
<stats:buildGraph id="TestDuration" valueType="TestDuration" height="200" width="500" isPredefined="${true}"
                  defaultFilter="showFailed" controllerUrl="buildGraph.html" hideTitle="true"
                  additionalProperties="testNameId"/>
