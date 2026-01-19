<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="problems" tagdir="/WEB-INF/tags/problems" %>
<%--@elvariable id="buildData" type="jetbrains.buildServer.serverSide.SBuild"--%>
<%--@elvariable id="compileErrors" type="java.util.List<String>"--%>
<%--@elvariable id="compactMode" type="java.lang.Boolean"--%>
<%--@elvariable id="buildProblem" type="jetbrains.buildServer.serverSide.problems.BuildProblem"--%>
<%--@elvariable id="buildProblemUID" type="java.lang.String"--%>
<%--@elvariable id="showExpanded" type="java.lang.String"--%>
<c:if test="${!compactMode && not empty compileErrors}">
  <problems:buildProblemDetails uid="${buildProblemUID}" insertIcons="true" expand="${showExpanded}" buildProblem="${buildProblem}">
    <div id="fullCompileErrorsData" class="compiler-errors">
      <div class="compiler-errors-actions">
        <a href="#" onclick="BS.Activator.doOpen('compilation?buildId=${buildData.buildId}'); return false"
           title="Open compilation errors in IDE" <bs:iconLinkStyle icon="IDE"/>>Open in IDE</a>
      </div>
      <ul id="compileErrorsData" class="compiler-errors">
        <c:forEach items="${compileErrors}" var="error" varStatus="status">
          <c:set var="id" value="message-${status.index}"/>
          <li class="compiler-error">${error}</li>
        </c:forEach>
      </ul>
    </div>
  </problems:buildProblemDetails>
</c:if>

