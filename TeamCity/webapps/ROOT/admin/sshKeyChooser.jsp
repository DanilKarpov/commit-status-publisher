<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>

<props:selectProperty id="${chooserId}" name="${chooserName}" enableFilter="true" className="longField" disabled="${readOnly}">
  <props:option value="">-- Choose an SSH key --</props:option>
  <c:forEach var="projectKeys" items="${sshKeys}">
    <c:set var="p" value="${projectKeys.key}"/>
    <c:set var="keys" value="${projectKeys.value}"/>
    <optgroup label="&ndash;&ndash; ${p.name} keys &ndash;&ndash;">
      <c:forEach items="${keys}" var="key">
        <props:option value="${key.name}" className="${key.encrypted ? 'encrypted' : ''}">${key.name}</props:option>
      </c:forEach>
    </optgroup>
  </c:forEach>
</props:selectProperty>
<c:if test="${not empty keySelectionCallback}">
  <script type="text/javascript">
    $j('#${chooserId}').change(function() {
      var encrypted = $j(this.options[this.selectedIndex]).hasClass('encrypted');
      ${keySelectionCallback}(encrypted);
    });

    $j(document).ready(function() {
      var chooser = $j('#${chooserId}');
      if (chooser.closest("no-display").length == 0) {
        var encrypted = chooser.find(':selected').hasClass('encrypted');
        ${keySelectionCallback}(encrypted);
      }
    });
  </script>
</c:if>
