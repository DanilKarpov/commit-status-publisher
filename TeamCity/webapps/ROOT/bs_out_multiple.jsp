<%@ include file="include-internal.jsp"
%><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%--@elvariable id="debug" type="java.lang.Boolean"--%><%--@elvariable id="content" type="java.lang.String"--%><%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
<c:if test="${true == debug}">
<bs:jquery/>
<bs:prototype/>
<bs:commonFrameworks/>
<bs:predefinedIntProps/>
<bs:baseUri/>
<bs:linkScript>
  <%-- BS - utility components --%>
  /js/bs/bs.js
  /js/bs/cookie.js
  /js/bs/resize.js
  /js/bs/position.js
  /js/bs/refresh.js

  <%-- BS - common components --%>
  /js/bs/tabs.js
  /js/bs/forms.js
  /js/bs/basePopup.js
  /js/bs/menuList.js
  /js/bs/modalDialog.js
  /js/bs/investigation.js
  /js/bs/changeBuildStatus.js
  /js/bs/tree.js
  /js/bs/issues.js
  /js/bs/pluginProperties.js
  /js/bs/serverLink.js
  /js/bs/activation.js
  /js/bs/datepicker.js
  /js/bs/tags.js
  /js/bs/backgroundLoader.js
  /js/bs/bs-clipboard.js

</bs:linkScript>
<bs:linkCSS>
  /css/FontAwesome/css/font-awesome.min.css
  /css/main.css
  /css/icons.css
  /css/tabs.css
  /css/buildLog/buildResultsDiv.css
  /css/testGroups.css
  /css/testList.css
  /css/investigation.css
  /css/statusChangeLink.css
  /css/tree/oldTree.css
  /css/tree/tree.css
  /css/projectHierarchy.css
  /css/tags.css

  /css/quickLinksPopUp.css
  /css/forms.css
  /css/runCustomBuild.css
  /css/issues.css
  /css/ellipsis.css

  /css/autocompletion.css
</bs:linkCSS>
<bs:commonTemplates/>
</c:if>
[<c:forEach var="content" items="${contents}" varStatus="status">"<c:set var="processed"><bs:out value="${content}" resolverContext="${project}"/></c:set>${fn:trim(processed)}"<c:if test="${!status.last}">,</c:if></c:forEach>]
