<%@include file="/include-internal.jsp"
%><jsp:useBean id="parameterConstants" class="jetbrains.buildServer.controllers.parameters.ParameterConstants"

/><jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterRenderContext"
/><jsp:useBean id="js" scope="request" type="java.lang.String"
/><jsp:useBean id="label" scope="request" type="java.lang.String"
/><jsp:useBean id="description" scope="request" type="java.lang.String"
/><jsp:useBean id="isRequired" scope="request" type="java.lang.Boolean"/>

<c:set var="jsId">'<bs:forJs>${context.id}</bs:forJs>'</c:set>
<c:set var="jsHolder" value="${js}.extra[${jsId}]"/>

<tr id="${context.id}_container" class="non_serializable_form_elements_container custom_container_control_${context.id}">
  <th>
    <label for="${context.id}">
      <bs:trim maxlength="45">${label}</bs:trim><c:if test="${isRequired}"><l:star/></c:if>
    </label>
  </th>
  <td>
    <div class="longField">
    <script type="text/javascript">
      ${jsHolder} = ${js}.register(${jsId});
    </script>

    <ext:typedParameter context="${context}" js="${jsHolder}"/>

    <c:if test="${fn:length(description) gt 0}">
      <span class="smallNote"><c:out value="${description}"/></span>
    </c:if>
    <span id="error_${context.id}" class="error"></span>
    </div>
  </td>
</tr>

