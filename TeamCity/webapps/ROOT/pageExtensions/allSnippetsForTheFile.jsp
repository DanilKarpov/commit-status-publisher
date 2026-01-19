<%--@elvariable id="snippet" type="jetbrains.buildServer.web.openapi.PageExtension"--%>
<%--@elvariable id="snippets" type="java.util.List<jetbrains.buildServer.web.openapi.PageExtension>"--%>
<%@ include file="../include-internal.jsp" %>
<%@ include file="include-snippet.jsp" %>
<span><bs:activateFileLink fileName="${changedFile.relativeFileName}" projectName="${projectName}"/></span>
<c:forEach items="${snippets}" var="snippet">
  <ext:includeExtension extension="${snippet}" isInHead="${false}" includeCSS="${true}" includeJS="${true}" includeContent="${true}"/>
</c:forEach>