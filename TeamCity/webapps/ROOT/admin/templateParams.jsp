<%@include file="/include-internal.jsp"%>
<jsp:useBean id="template" scope="request" type="jetbrains.buildServer.serverSide.BuildTypeTemplate"/>
<jsp:useBean id="paramNames" scope="request" type="java.util.Collection"/>
<jsp:useBean id="templateParameters" scope="request" type="java.util.Map"/>
<c:if test="${not empty paramNames}">
  <table class="runnerFormTable templateParametersTable">
    <tr class="groupingTitle">
      <td colspan="2">Template parameters</td>
    </tr>
  <c:forEach items="${paramNames}" var="paramName" varStatus="pos">
    <c:set var="escapedParamName"><c:out value="${paramName}"/></c:set>
    <c:set var="paramId">${template.id}_param_${pos.index}</c:set>
    <tr>
      <td class="name"><label for="${paramId}"><bs:makeBreakable text="${paramName}" regex="[._:-]+"/>:</label></td>
      <td class="value">
        <div class="completionIconWrapper">
          <forms:textField name="param:${escapedParamName}" id="${paramId}" value="${templateParameters[paramName]}" className="buildTypeParams longField" expandable="true"/>
        </div>
      </td>
    </tr>
  </c:forEach>
  </table>
  <script type="text/javascript">
    BS.AvailableParams.attachPopups("settingsId=template:${template.externalId}");
  </script>
</c:if>
